// @flow

const path = require('path');
const fs = require('fs-extra');

const {createTestSandbox, promiseExec, skipSuiteOnWindows} = require('../test/helpers');
const fixture = require('./fixture.js');

skipSuiteOnWindows('#301');

describe('Common - build-env', () => {
  it('generates an environment with deps in $PATH', async () => {
    const p = await createTestSandbox(...fixture.simpleProject);

    await p.esy('build');

    const buildEnv = (await p.esy('build-env')).stdout;

    await fs.writeFile(path.join(p.projectPath, 'build-env'), buildEnv);

    await expect(
      promiseExec('. ./build-env && dep', {
        cwd: p.projectPath,
      }),
    ).resolves.toEqual({stdout: '__dep__\n', stderr: ''});

    await expect(
      promiseExec('. ./build-env && devDep', {
        cwd: p.projectPath,
      }),
    ).rejects.toThrow();
  });
});
