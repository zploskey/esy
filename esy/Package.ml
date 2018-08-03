type t = {
  id : string;
  name : string;
  version : string;
  dependencies : dependencies;
  build : ((Manifest.Build.t [@equal fun _ _ -> true]) [@compare fun _ _ -> 0]);
  sourcePath : Config.Path.t;
  resolution : string option;
} [@@deriving (eq, ord)]

and dependencies =
  dependency list

and dependency =
  | Dependency of t
  | OptDependency of t
  | DevDependency of t
  | BuildTimeDependency of t
  | InvalidDependency of {
    pkgName: string;
    reason: string;
  }

type pkg = t
type pkg_dependency = dependency

let packageOf (dep : dependency) = match dep with
| Dependency pkg
| OptDependency pkg
| DevDependency pkg
| BuildTimeDependency pkg -> Some pkg
| InvalidDependency _ -> None

module Graph = DependencyGraph.Make(struct

  type t = pkg

  let compare a b = compare a b

  module Dependency = struct
    type t = pkg_dependency
    let compare a b = compare_dependency a b
  end

  let id (pkg : t) = pkg.id

  let traverse pkg =
    let f acc dep = match dep with
      | Dependency pkg
      | OptDependency pkg
      | DevDependency pkg
      | BuildTimeDependency pkg -> (pkg, dep)::acc
      | InvalidDependency _ -> acc
    in
    pkg.dependencies
    |> List.fold_left ~f ~init:[]
    |> List.rev

end)

module DependencySet = Set.Make(struct
  type t = dependency
  let compare = compare_dependency
end)
