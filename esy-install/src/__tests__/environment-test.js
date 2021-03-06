/**
 * @flow
 */

import {NoopReporter} from '@esy-ocaml/esy-install/src/reporters';
import type {BuildSpec} from '../types';
import {create as createConfig} from '../config';
import {fromBuildSpec} from '../build-task';
import * as Env from '../environment.js';

function build({name, exportedEnv, dependencies: dependenciesArray}): BuildSpec {
  const dependencies = new Map();
  for (const item of dependenciesArray) {
    dependencies.set(item.id, item);
  }
  return {
    id: name,
    idInfo: null,
    name,
    version: '0.1.0',
    dependencies,
    exportedEnv,
    sourcePath: name,
    packagePath: name,
    sourceType: 'immutable',
    buildType: 'out-of-source',
    buildCommand: [],
    installCommand: [],
    errors: [],
  };
}

const config = createConfig({
  reporter: new NoopReporter(),
  sandboxPath: '<sandboxPath>',
  storePath: '<storePath>',
  buildPlatform: 'linux',
});

const ocaml = build({
  name: 'ocaml',
  exportedEnv: {
    CAML_LD_LIBRARY_PATH: {
      val: "#{ocaml.lib / 'ocaml'}",
      scope: 'global',
    },
  },
  dependencies: [],
});

const ocamlfind = build({
  name: 'ocamlfind',
  exportedEnv: {
    CAML_LD_LIBRARY_PATH: {
      val: "#{ocamlfind.lib / 'ocaml' : $CAML_LD_LIBRARY_PATH}",
      scope: 'global',
    },
  },
  dependencies: [ocaml],
});

const lwt = build({
  name: 'lwt',
  exportedEnv: {
    CAML_LD_LIBRARY_PATH: {
      val: "#{lwt.lib / 'ocaml' : $CAML_LD_LIBRARY_PATH}",
      scope: 'global',
    },
  },
  dependencies: [ocaml],
});

test('printing environment', function() {
  const app = build({
    name: 'app',
    exportedEnv: {
      CAML_LD_LIBRARY_PATH: {
        val: '#{app.lib : $CAML_LD_LIBRARY_PATH}',
        scope: 'global',
      },
    },
    dependencies: [ocamlfind, lwt],
  });
  const {env} = fromBuildSpec(app, config);
  expect(Env.printEnvironment(env)).toMatchSnapshot();
});

test('eval environment', function() {
  const app = build({
    name: 'app',
    exportedEnv: {
      CAML_LD_LIBRARY_PATH: {
        val: '#{app.lib : $CAML_LD_LIBRARY_PATH}',
        scope: 'global',
      },
    },
    dependencies: [ocamlfind, lwt],
  });
  const {env} = fromBuildSpec(app, config);
  expect(Env.evalEnvironment(env)).toMatchSnapshot();
});
