# Zyntax NDK r29

An Android-ARM64 host port of NDK **r29 / 29.0.14206865**. This is a public,
standalone toolchain project; it does not contain or require Zyntax app source.

**Status: source port in progress. No verified release is available yet.**

## Design

- Build the r29 compiler from its recorded LLVM source and Android changes.
- Use dynamic Android host executables so ordinary process launch and runtime
  environment handling remain available. Do not reuse fully static host tools.
- Preserve the official target sysroot, runtimes and NDK version metadata.
- Identify the actual host architecture; do not add x86-directory aliases.
- Use Bash for shell entrypoints and explicit tool dependencies.
- Keep exact NDK versions separately installable. NDK r28 is deferred.

The available community r29 archive was inspected, not installed: its compiler,
Make and Python binaries are fully static, and its LLDB entrypoint delegates to
an external executable. It is not the source of release host binaries here.

## Repository roles

- This repository: pinned source inputs, Android-host portability changes,
  build scripts, notices and verification evidence.
- `zyntax-packages`: `.deb` recipes and package builds consuming verified output.
- `zyntax-packages-repo`: signed APT publication at `pkg.zyntax.app`.
- App/SDK: unchanged. Studio UI is deferred until the toolchain works headlessly.

## Roadmap

- [x] Inspect the r29 candidate and reject static tools and fallback wrappers.
- [x] Verify publishing authentication and the connected USB device.
- [ ] Pin official r29 source inputs and preserve source/license provenance.
- [ ] Build dynamic Android-ARM64 Clang, LLD and LLVM binary utilities.
- [ ] Port NDK host discovery and Bash entrypoints without architecture aliases.
- [ ] Audit and complete the remaining host tools and distribution notices.
- [ ] Address AGP's desktop-only NDK host lookup through proper tooling source
      changes, not app code, binary modification or a disguised host directory.
- [ ] Package the exact NDK revision as a coinstallable `.deb`.
- [ ] Verify CMake and `ndk-build` on USB, without UI navigation.
- [ ] Verify native sample APK/AAB builds and signatures; keys stay outside
      projects under the app's `~/.secrets`.
- [ ] Verify Zyntax's Android project with its declared r29; do not publish APKs.
- [ ] Publish the verified package and check signed repository installation.

Earlier sample APK/AAB signing checks succeeded without an NDK. Their device
copies required compile SDK 37 for their declared AndroidX dependencies; those
results are not evidence of native compilation or unchanged-project support.

## License

Original infrastructure is [Apache-2.0](LICENSE). Upstream software keeps its
own licenses; see [NOTICE.md](NOTICE.md). Generated sources, binaries and local
credentials are excluded from Git.
