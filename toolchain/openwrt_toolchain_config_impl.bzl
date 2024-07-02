load(
    "//toolchain:common.bzl",
    _canonical_dir_path = "canonical_dir_path",
    _generate_build_file = "generate_build_file",
    _is_absolute_path = "is_absolute_path",
    _join = "join",
    _list_to_string = "list_to_string",
)

BZLMOD_ENABLED = "@@" in str(Label("//:unused"))

def _is_hermetic_or_exists(rctx, path, sysroot_path):
    path = path.replace("%sysroot%", sysroot_path).replace("//", "/")
    if not path.startswith("/"):
        return True
    return rctx.path(path).exists

def openwrt_toolchain_config_impl(rctx):
    suffix = "{}_{}".format(rctx.attr.chip_model, rctx.attr.chip_version)
    system_llvm = False
    if _is_absolute_path(rctx.attr.url):
        system_llvm = True
        toolchain_path_prefix = _canonical_dir_path(rctx.attr.url)
    if not system_llvm:
        toolchain_repo_root = ("@" if BZLMOD_ENABLED else "") + "@openwrt_toolchain_repo_{}//".format(suffix)
        toolchain_path_prefix = _canonical_dir_path(str(rctx.path(Label(toolchain_repo_root + ":BUILD.bazel")).dirname))

    cc_toolchain_config_bzl = "@toolchains_openwrt//toolchain:openwrt_cc_toolchain_config.bzl"
    symlinked_tools = ""
    extra_compiler_files = ("\"%s\"," % str(rctx.attr.extra_compiler_files)) if rctx.attr.extra_compiler_files else ""
    cxx_builtin_include_directories = [
        toolchain_path_prefix + "include",
        toolchain_path_prefix + "aarch64-openwrt-linux-musl/include/c++/12.3.0",
        toolchain_path_prefix + "aarch64-openwrt-linux-musl/sys-include",
    ]

    sysroot_label_str = ""
    sysroot_path = ""
    if rctx.attr.sysroot:
        if _is_absolute_path(rctx.attr.sysroot):
            sysroot_path = rctx.attr.sysroot
        else:
            sysroot_label = rctx.attr.sysroot
    if rctx.attr.sysroot:
        sysroot_prefix = "%sysroot%"
        cxx_builtin_include_directories.extend([
            _join(sysroot_prefix, "/include"),
            _join(sysroot_prefix, "/usr/include"),
            _join(sysroot_prefix, "/usr/local/include"),
        ])

    cxx_builtin_include_directories = _list_to_string([
        dir
        for dir in cxx_builtin_include_directories
        if _is_hermetic_or_exists(rctx, dir, sysroot_path)
    ])

    target_arch = rctx.attr.arch
    target_settings = ""
    target_system_name = "aarch64-linux"

    ##target_system_name= "armeabi-linux"
    ##target_system_name= "armv7a-linux"
    ##target_system_name= "armv7-linux"
    if rctx.attr.compile_flags:
        compile_flags_str = _list_to_string(rctx.attr.compile_flags)
    if rctx.attr.cxx_flags:
        cxx_flags_str = _list_to_string(rctx.attr.cxx_flags)
    if rctx.attr.link_flags:
        link_flags_str = _list_to_string(rctx.attr.link_flags)
    if rctx.attr.archive_flags:
        archive_flags_str = _list_to_string(rctx.attr.archive_flags)
    if rctx.attr.link_libs:
        link_libs_str = _list_to_string(rctx.attr.link_libs)
    if rctx.attr.opt_compile_flags:
        opt_compile_flags_str = _list_to_string(rctx.attr.opt_compile_flags)
    if rctx.attr.opt_link_flags:
        opt_link_flags_str = _list_to_string(rctx.attr.opt_link_flags)
    if rctx.attr.dbg_compile_flags:
        dbg_compile_flags_str = _list_to_string(rctx.attr.dbg_compile_flags)
    if rctx.attr.coverage_compile_flags:
        coverage_compile_flags_str = _list_to_string(rctx.attr.coverage_compile_flags)
    if rctx.attr.coverage_link_flags:
        coverage_link_flags_str = _list_to_string(rctx.attr.coverage_link_flags)
    if rctx.attr.unfiltered_compile_flags:
        unfiltered_compile_flags_str = _list_to_string(rctx.attr.unfiltered_compile_flags)

    compiler_configuration = {
      "compile_flags": %{compile_flags_str},
      "cxx_flags": %{cxx_flags_str},
      "link_flags": %{link_flags_str},
      "archive_flags": %{archive_flags_str},
      "link_libs": %{link_libs},
      "opt_compile_flags": %{opt_compile_flags_str},
      "opt_link_flags": %{opt_link_flags_str},
      "dbg_compile_flags": %{dbg_compile_flags_str},
      "coverage_compile_flags": %{coverage_compile_flags_str},
      "coverage_link_flags": %{coverage_link_flags_str},
      "unfiltered_compile_flags": %{unfiltered_compile_flags_str},
    },
    #filenames = []
    #for libname in _aliased_libs:
    #filename = "lib/{}.{}".format(libname, exec_dl_ext)
    #filenames.append(filename)
    #for toolname in _aliased_tools:
    #filename = "bin/{}".format(toolname)
    #filenames.append(filename)

    #for filename in filenames:
    #rctx.symlink(llvm_dist_rel_path + filename, filename)

    rctx.template(
        "bin/cc_wrapper.sh",
        Label("//toolchain:wrapper.sh.tpl"),
        {
            "%{toolchain_path_prefix}": toolchain_path_prefix,
        },
    )

    rctx.template(
        "BUILD.bazel",
        "//toolchain:openwrt_cc_toolchain_config.BUILD.tpl",
        {
            "%{suffix}": suffix,
            "%{target_system_name}": target_system_name,
            "%{cc_toolchain_config_bzl}": str(cc_toolchain_config_bzl),
            "%{target_settings}": target_settings,
            "%{target_os_bzl}": "linux",
            "%{sysroot_label_str}": sysroot_label_str,
            "%{sysroot_path}": sysroot_path,
            "%{toolchain_path_prefix}": toolchain_path_prefix,
            "%{cxx_builtin_include_directories}": cxx_builtin_include_directories,
            "%{symlinked_tools}": symlinked_tools,
            #"%{wrapper_bin_prefix}": wrapper_bin_prefix,
            "%{compile_flags}": compile_flags_str,
            "%{cxx_flags}": cxx_flags_str,
            "%{link_flags}": link_flags_str,
            "%{archive_flags}": archive_flags_str,
            "%{link_libs}": link_libs_str,
            "%{opt_compile_flags}": opt_compile_flags_str,
            "%{opt_link_flags}": opt_link_flags_str,
            "%{dbg_compile_flags}": dbg_compile_flags_str,
            "%{coverage_compile_flags}": coverage_compile_flags_str,
            "%{coverage_link_flags}": coverage_link_flags_str,
            "%{unfiltered_compile_flags}": unfiltered_compile_flags_str,
        },
    )
    _generate_build_file(rctx)
