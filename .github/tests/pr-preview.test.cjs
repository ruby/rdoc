const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const path = require('node:path');
const test = require('node:test');

// Use the workflow scripts themselves, not a second implementation of the resolver.
const workflows = JSON.parse(execFileSync('ruby', ['-ryaml', '-rjson', '-e',
  'puts JSON.generate(ARGV.map { |file| YAML.load_file(file) })',
  '.github/workflows/cloudflare-preview.yml', '.github/workflows/pr-preview-check.yml',
], { cwd: path.resolve(__dirname, '../..'), encoding: 'utf8' }));
const [deployment, build] = workflows;
const resolveScript = deployment.jobs.resolve.steps[0].with.script;
const currentStep = deployment.jobs.deploy.steps.find(step => step.id === 'current');
const commentStep = deployment.jobs.deploy.steps.find(step => step.name === 'Update preview comment');
const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
const sha = 'a'.repeat(40);
const artifact = { name: 'pr-preview-site', expired: false, size_in_bytes: 1000 };

function pull(number = 1, base = 'master', branch = 'child') {
  return {
    number, state: 'open',
    base: { ref: base, repo: { full_name: 'ruby/rdoc' } },
    head: { sha, ref: branch, repo: { full_name: 'contributor/rdoc' } },
  };
}

async function execute(script, {
  pulls = [pull()], associated = [], conclusion = 'success', artifacts = [artifact],
  jobs = [{ conclusion: 'success' }], env = {}, comments = [],
} = {}) {
  const outputs = {}, failures = [], writes = [], calls = [];
  const rest = {
    pulls: {
      list: () => {},
      get: async ({ pull_number }) => ({ data: pulls.find(pr => pr.number === pull_number) }),
    },
    actions: { listWorkflowRunArtifacts: () => {}, listJobsForWorkflowRun: () => {} },
    issues: {
      listComments: () => {},
      createComment: async args => writes.push({ action: 'create', ...args }),
      updateComment: async args => writes.push({ action: 'update', ...args }),
    },
  };
  const github = { rest, paginate: async (method, args) => {
    calls.push(args);
    if (method === rest.pulls.list) {
      return pulls.filter(pr => pr.state === args.state &&
        `contributor:${pr.head.ref}` === args.head && (!args.base || pr.base.ref === args.base));
    }
    if (method === rest.actions.listWorkflowRunArtifacts) return artifacts;
    if (method === rest.actions.listJobsForWorkflowRun) return jobs;
    if (method === rest.issues.listComments) return comments;
    throw new Error('Unexpected API call');
  } };
  const context = { repo: { owner: 'ruby', repo: 'rdoc' }, payload: { workflow_run: {
    id: 123, conclusion, head_sha: sha, head_branch: 'child',
    head_repository: { full_name: 'contributor/rdoc', owner: { login: 'contributor' } },
    pull_requests: associated.map(number => ({ number })),
  } } };
  await new AsyncFunction('context', 'github', 'core', 'process', script)(
    context, github, {
      setOutput: (key, value) => { outputs[key] = value; },
      setFailed: message => failures.push(message), notice: () => {},
    }, { env },
  );
  return { outputs, failures, writes, calls };
}

for (const associated of [[], [1, 2], [2]]) {
  test(`same head supports each associated PR: ${JSON.stringify(associated)}`, async () => {
    const result = await execute(resolveScript, { pulls: [pull(), pull(2, 'parent')], associated });
    assert.deepEqual(result.failures, []);
    const numbers = associated.length ? associated : [1, 2];
    assert.deepEqual(JSON.parse(result.outputs.pull_requests), numbers.map(number => ({
      number, head_sha: sha, base_ref: number === 1 ? 'master' : 'parent',
    })));
    assert.ok(result.calls.some(call => call.run_id === 123 && call.name === artifact.name));
  });
}

test('ordinary stacked PR resolves independently of its parent', async () => {
  const result = await execute(resolveScript, { pulls: [pull(1, 'master', 'parent'), pull(2, 'parent')] });
  assert.deepEqual(JSON.parse(result.outputs.pull_requests), [{ number: 2, head_sha: sha, base_ref: 'parent' }]);
});

for (const change of ['closed', 'stale', 'head repository', 'head branch', 'base repository']) {
  test(`a ${change} candidate does not block another current PR`, async () => {
    const invalid = pull(2, 'parent');
    if (change === 'closed') invalid.state = 'closed';
    if (change === 'stale') invalid.head.sha = 'b'.repeat(40);
    if (change === 'head repository') invalid.head.repo.full_name = 'other/rdoc';
    if (change === 'head branch') invalid.head.ref = 'other';
    if (change === 'base repository') invalid.base.repo.full_name = 'other/rdoc';
    const result = await execute(resolveScript, { pulls: [pull(), invalid], associated: [1, 2] });
    assert.deepEqual(result.failures, []);
    assert.deepEqual(JSON.parse(result.outputs.pull_requests), [{ number: 1, head_sha: sha, base_ref: 'master' }]);
  });
}

test('no current PR produces no deployment targets', async () => {
  const result = await execute(resolveScript, { pulls: [] });
  assert.deepEqual(result.failures, []);
  assert.equal(result.outputs.pull_requests, '[]');
});

for (const conclusion of ['success', 'failure']) {
  test(`${conclusion} with a valid artifact produces a preview`, async () => {
    const result = await execute(resolveScript, { conclusion });
    assert.deepEqual(result.failures, []);
    assert.equal(JSON.parse(result.outputs.pull_requests).length, 1);
  });
}

for (const [name, options, errors] of [
  ['intentional skip', { artifacts: [], jobs: [{ conclusion: 'skipped' }] }, 0],
  ['failed build', { artifacts: [], conclusion: 'failure' }, 0],
  ['cancelled build', { conclusion: 'cancelled' }, 0],
  ['missing upload', { artifacts: [] }, 1],
  ['missing jobs and upload', { artifacts: [], jobs: [] }, 1],
  ['expired upload', { artifacts: [{ ...artifact, expired: true }] }, 1],
  ['duplicate upload', { artifacts: [artifact, artifact] }, 1],
  ['oversized upload', { artifacts: [{ ...artifact, size_in_bytes: 501 * 1024 * 1024 }] }, 1],
]) {
  test(`${name} cannot deploy`, async () => {
    const result = await execute(resolveScript, options);
    assert.equal(result.failures.length, errors);
    assert.equal(result.outputs.pull_requests, '[]');
  });
}

for (const change of ['base', 'head', 'state']) {
  test(`a changed ${change} only skips that PR's deployment and comment`, async () => {
    const pulls = [pull(), pull(2, 'parent')];
    const resolved = await execute(resolveScript, { pulls });
    if (change === 'base') pulls[1].base.ref = 'retargeted';
    if (change === 'head') pulls[1].head.sha = 'b'.repeat(40);
    if (change === 'state') pulls[1].state = 'closed';
    for (const target of JSON.parse(resolved.outputs.pull_requests)) {
      const env = {
        PR_NUMBER: String(target.number), EXPECTED_SHA: target.head_sha, EXPECTED_BASE_REF: target.base_ref,
        PREVIEW_ALIAS_URL: `https://${target.number}-preview.rdoc-6cd.pages.dev/`,
      };
      const current = await execute(currentStep.with.script, { pulls, env });
      assert.equal(current.outputs.current, String(target.number === 1));
      const result = await execute(commentStep.with.script, { pulls, env });
      assert.equal(result.writes.length, target.number === 1 ? 1 : 0);
      if (target.number === 1) assert.equal(result.writes[0].issue_number, 1);
    }
  });
}

test('preview updates reuse the marked bot comment', async () => {
  const result = await execute(commentStep.with.script, {
    env: { PR_NUMBER: '1', EXPECTED_SHA: sha, EXPECTED_BASE_REF: 'master', PREVIEW_ALIAS_URL: 'https://1-preview.rdoc-6cd.pages.dev/' },
    comments: [{ id: 55, user: { login: 'github-actions[bot]' }, body: '<!-- rdoc-pr-preview -->\nold' }],
  });
  assert.equal(result.writes[0].action, 'update');
  assert.equal(result.writes[0].comment_id, 55);
});

test('only source changes and base retargets run the build', () => {
  const allowed = new Function('github', `return Boolean(${build.jobs.build.if});`);
  for (const action of ['opened', 'synchronize', 'reopened', 'edited']) {
    for (const field of ['title', 'body', 'base']) {
      const github = { repository: 'ruby/rdoc', event: { action, changes: { [field]: {} } } };
      assert.equal(allowed(github), action !== 'edited' || field === 'base', `${action}: ${field}`);
    }
  }
  // Job-scoped concurrency prevents skipped metadata edits from cancelling an active build.
  assert.equal(build.concurrency, undefined);
  assert.equal(build.jobs.build.concurrency.group, 'pr-preview-build-${{ github.event.pull_request.number }}');
  assert.equal(build.jobs.build.concurrency['cancel-in-progress'], true);
});

test('matrix deployments use separate PR aliases and cancellation groups', () => {
  const job = deployment.jobs.deploy;
  const allowed = new Function('needs', `return Boolean(${job.if});`);
  assert.equal(allowed({ resolve: { outputs: { pull_requests: '[]' } } }), false);
  assert.equal(allowed({ resolve: { outputs: { pull_requests: '[{"number":1}]' } } }), true);
  assert.equal(job.strategy['fail-fast'], false);
  assert.equal(job.strategy.matrix.pull_request, '${{ fromJSON(needs.resolve.outputs.pull_requests) }}');
  assert.equal(job.concurrency.group, 'pr-preview-deploy-${{ matrix.pull_request.number }}');
  for (const step of [currentStep, commentStep]) {
    assert.equal(step.env.PR_NUMBER, '${{ matrix.pull_request.number }}');
    assert.equal(step.env.EXPECTED_SHA, '${{ matrix.pull_request.head_sha }}');
    assert.equal(step.env.EXPECTED_BASE_REF, '${{ matrix.pull_request.base_ref }}');
  }
  assert.match(job.steps.find(step => step.id === 'deploy').with.command,
    /--branch="\$\{\{ matrix\.pull_request\.number \}\}-preview"/);
});
