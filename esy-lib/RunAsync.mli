(**
 * An async computation which might result in an error.
 *)

type 'a t = 'a Run.t Lwt.t

(**
 * Computation which results in a value.
 *)
val return : 'a -> 'a t

(**
 * Computation which results in an error.
 *)
val error : string -> 'a t

(**
 * Wrap computation with a context which will be reported in case of error.
 *
 * Example usage:
 *
 *   let build = withContext "building ocaml" build in ...
 *
 * In case build fails the error message would look like:
 *
 *   Error: command not found aclocal
 *     While building ocaml
 *
 *)
val withContext : string -> 'a t -> 'a t

(**
 * Same as with the [withContext] but will be formatted as differently, as a
 * single block of text.
 *)
val withContextOfLog : ?header:string -> string -> 'a t -> 'a t

(**
 * Run computation and throw an exception in case of a failure.
 *
 * Optional [err] will be used as error message.
 *)
val runExn : ?err : string -> 'a t -> 'a

(**
 * Convert [Run.t] into [t].
 *)
val ofRun : 'a Run.t -> 'a t

(**
 * Convert an Rresult into [t]
 *)
val ofResult: ?err : string -> ('a, 'b) Result.result -> 'a t

(**
 * Convert [option] into [t].
 *
 * [Some] will represent success and [None] a failure.
 *
 * An optional [err] will be used as an error message in case of failure.
 *)
val ofOption : ?err : string -> 'a option -> 'a t

(**
 * Convenience module which is designed to be openned locally with the
 * code which heavily relies on RunAsync.t.
 *
 * This also brings Let_syntax module into scope and thus compatible with
 * ppx_let.
 *
 * Example
 *
 *    let open RunAsync.Syntax in
 *    let%bind v = fetchNumber ... in
 *    if v > 10
 *    then return (v + 1)
 *    else error "Less than 10"
 *
 *)
module Syntax : sig

  val return : 'a -> 'a t

  val error : string -> 'a t

  module Let_syntax : sig
    val bind : f:('a -> 'b t) -> 'a t -> 'b t
    val both : 'a t -> 'b t -> ('a * 'b) t
  end
end

(**
 * Work with lists of computations.
 *)
module List : sig
  val foldLeft : f:('a -> 'b -> 'a t) -> init:'a -> 'b list -> 'a t
  val waitAll : unit t list -> unit t
  val joinAll : 'a t list -> 'a list t
  val processSeq :
    f:('a -> unit t) -> 'a list -> unit t
end
