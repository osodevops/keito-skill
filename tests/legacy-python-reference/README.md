# Historical Python implementation — development reference only

These exact bytes preserve the abandoned helper/interpreter-pin design and its
behavioral fault assertions. They are excluded from the installed native payload
and are not called by `tests/run.sh`. Do not run these archived entrypoints: their
original relative source layout no longer exists. Use the native Rust tests in
keito-cli and the explicitly isolated fake-core shell suite instead.

The manifest records previous paths, byte hashes and modes. All earlier failures,
including real startup/deadline failures and the later unintended global test
installation, remain in the task evidence. Archival does not make those results
successful or establish native/runtime qualification.
