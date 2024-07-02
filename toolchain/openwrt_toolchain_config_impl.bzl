load(
    "//toolchain:common.bzl",
    _canonical_dir_path = "canonical_dir_path",
    _generate_build_file = "generate_build_file",
    _is_absolute_path = "is_absolute_path",
    _join = "join",
    _list_to_string = "list_to_string",
)

BZLMOD_ENABLED = "@@" in str(Label("//:unused"))

def openwrt_toolchain_config_impl(rctx):
    suffix = "{}_{}".format(rctx.attr.chip_model, rctx.attr.chip_version)
    system_llvm = False
    if _is_absolute_path(rctx.attr.url):
        system_llvm = True
        toolchain_path_prefix = _canonical_dir_path(rctx.attr.url)
    if not system_llvm:
        toolchain_repo_root = ("@" if BZLMOD_ENABLED else "") + "@openwrt_toolchain_repo_{}//".format(suffix)
        toolchain_path_prefix = _canonical_dir_path(str(rctx.path(Label(toolchain_repo_root + ":BUILD.bazel")).dirname))

    _generate_build_file(rctx)
    cc_toolchain_config_bzl = "@toolchains_openwrt//toolchain:openwrt_cc_toolchain_config.bzl"
    symlinked_tools = ""
    extra_compiler_files = ("\"%s\"," % str(rctx.attr.extra_compiler_files)) if rctx.attr.extra_compiler_files else ""
    cxx_builtin_include_directories = [
        toolchain_path_prefix + "include",
        toolchain_path_prefix + "aarch64-openwrt-linux-musl/include/c++/12.3.0",
        toolchain_path_prefix + "aarch64-openwrt-linux-musl/sys-include",
    ]

    if rctx.attr.sysroot:
        if _is_absolute_path(rctx.attr.sysroot):
            sysroot_path = rctx.attr.sysroot
        else:
            sysroot_label = rctx.attr.sysroot
    if sysroot_path:
        sysroot_prefix = "%sysroot%"
        cxx_builtin_include_directories.extend([
            _join(sysroot_prefix, "/include"),
            _join(sysroot_prefix, "/usr/include"),
            _join(sysroot_prefix, "/usr/local/include"),
        ])

    target_arch = rctx.attr.arch
    target_settings = ""
    target_system_name = "aarch64-linux"

    ##target_system_name= "armeabi-linux"
    ##target_system_name= "armv7a-linux"
    ##target_system_name= "armv7-linux"
    #compile_flags
    compile_flags = _list_to_string(compile_flags)
    cxx_flags_str = _list_to_string(cxx_flags)
    link_flags_str = _list_to_string(link_flags)
    archive_flags_str = _list_to_string(archive_flags)
    link_libs_str = _list_to_string(link_libs)
    opt_compile_flags_str = _list_to_string(opt_compile_flags)
    opt_link_flags_str = _list_to_string(opt_link_flags)
    dbg_compile_flags_str = _list_to_string(dbg_compile_flags)
    coverage_compile_flags_str = _list_to_string(coverage_compile_flags)
    coverage_link_flags_str = _list_to_string(coverage_link_flags)
    unfiltered_compile_flags_str = _list_to_string(unfiltered_compile_flags)

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
        "BUILD.bazel",
        rctx.attr._build_toolchain_tpl,
        {
            "%{suffix}": suffix,
            "%{target_system_name}": target_system_name,
            "%{cc_toolchain_config_bzl}": cc_toolchain_config_bzl,
            "%{target_settings}": target_settings,
            "%{target_os_bzl}": target_os_bzl,
            "%{sysroot_label_str}": sysroot_label_str,
            "%{sysroot_path}": sysroot_path,
            "%{toolchain_path_prefix}": toolchain_path_prefix,
            "%{cxx_builtin_include_directories}": cxx_builtin_include_directories,
            "%{cc_toolchain_config_bzl}": str(rctx.attr._cc_toolchain_config_bzl),
            "%{cc_toolchains}": cc_toolchains_str,
            "%{symlinked_tools}": symlinked_tools_str,
            "%{wrapper_bin_prefix}": wrapper_bin_prefix,
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
