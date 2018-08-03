module EsyBash = EsyLib.EsyBash
module Fs = EsyLib.Fs
module Path = EsyLib.Path
module RunAsync = EsyLib.RunAsync
module Result = EsyLib.Result

let%test "creates and unpacks a tarball" =
    let test () = 
        let f tempPath =
            let folderToCreate = Path.(tempPath / "test-folder") in
            let%lwt _ = Fs.createDir folderToCreate in
            let fileToCreate = Path.(folderToCreate / "test-file.txt") in
            let data = "test data" in
            let%lwt _ = Fs.writeFile ~data fileToCreate in

            (* package up the file into a tarball *)
            let filename = Path.(tempPath / "output.tar.gz") in
            let%lwt _ = EsyLib.Tarball.create ~filename folderToCreate in

            (* unpack the tarball *)
            let dst = Path.(tempPath / "extract-folder") in
            let%lwt _ = Fs.createDir dst in 
            let%lwt _ = EsyLib.Tarball.unpack ~dst filename in

            let expectedOutputFile = Path.(dst / "test-file.txt") in
            let%lwt result = Fs.readFile expectedOutputFile in
            match result with 
            | Ok v -> Lwt.return (v = data)
            | _ -> Lwt.return false
        in
        Fs.withTempDir f
    in
    TestLwt.runLwtTest test

let%test "unpack tarball with stripcomponents" =
    let test () = 
        let f tempPath =
            let folderToCreate = Path.(tempPath / "test-folder" / "nested-folder-1" / "nested-folder-2") in
            let%lwt _ = Fs.createDir folderToCreate in
            let fileToCreate = Path.(folderToCreate / "test-file.txt") in
            let data = "test data" in
            let%lwt _ = Fs.writeFile ~data fileToCreate in

            (* package up the file into a tarball *)
            let folderToPackage = Path.(tempPath / "test-folder") in
            let filename = Path.(tempPath / "output.tar.gz") in
            let%lwt _ = EsyLib.Tarball.create ~filename folderToPackage in

            (* unpack the tarball *)
            let dst = Path.(tempPath / "extract-folder") in
            let%lwt _ = Fs.createDir dst in 
            let stripComponents = 2 in
            let%lwt _ = EsyLib.Tarball.unpack ~stripComponents ~dst filename in

            let expectedOutputFile = Path.(dst / "test-file.txt") in
            let%lwt result = Fs.readFile expectedOutputFile in
            match result with 
            | Ok v -> Lwt.return (v = data)
            | _ -> Lwt.return false
        in
        Fs.withTempDir f
    in
    TestLwt.runLwtTest test

let%test "returns error if operation was not successfully" = 
    let test () =
        let dst = Path.(v "non-existent-path") in
        let fileName = Path.(v "non-existent-file.tgz") in
        let%lwt result = EsyLib.Tarball.unpack ~dst fileName in
        match result with
        | Ok _ -> Lwt.return false
        | _ -> Lwt.return true
    in
    TestLwt.runLwtTest test
