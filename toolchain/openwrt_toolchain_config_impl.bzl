load(
    "//toolchain:common.bzl",
    _canonical_dir_path = "canonical_dir_path",
    _dict_to_string = "dict_to_string",
    _generate_build_file = "generate_build_file",
    _is_absolute_path = "is_absolute_path",
    _join = "join",
    _list_to_string = "list_to_string",
    _pkg_path_from_label = "pkg_path_from_label",
)

BZLMOD_ENABLED = "@@" in str(Label("//:unused"))

def _is_hermetic_or_exists(rctx, path, sysroot_path):
    path = path.replace("%sysroot%", sysroot_path).replace("//", "/")
    if not path.startswith("/"):
        return True
    return rctx.path(path).exists

def openwrt_toolchain_config_impl(rctx):
    print(rctx.attr.toolchain_prefix)
    print(rctx.attr.tool_names)
    suffix = "{}_{}".format(rctx.attr.chip_model, rctx.attr.chip_version)
    system_llvm = False
    if _is_absolute_path(rctx.attr.url):
        system_llvm = True
        toolchain_path_prefix = _canonical_dir_path(rctx.attr.url)
    if not system_llvm:
        toolchain_repo_root = ("@" if BZLMOD_ENABLED else "") + "@openwrt_toolchain_repo_{}//".format(suffix)
        toolchain_path_prefix = _canonical_dir_path(str(rctx.path(Label(toolchain_repo_root + ":BUILD.bazel")).dirname))
    toolchain_path_prefix = toolchain_path_prefix + rctx.attr.toolchain_prefix
    toolchain_path_prefix.replace("//", "/")
    toolchain_path_prefix = _canonical_dir_path(toolchain_path_prefix)
    tool_paths = {}
    for k, v in rctx.attr.tool_names.items():
        tool_paths[k] = "\"{}bin/{}\"".format(toolchain_path_prefix, v)

    print(toolchain_path_prefix)
    print(tool_paths)

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
            sysroot_label = Label(rctx.attr.sysroot)
            sysroot_path = _pkg_path_from_label(sysroot_label)
            sysroot_label_str = "\"%s\"" % str(sysroot_label)

    if sysroot_path != "":
        sysroot_prefix = "%sysroot%"
        cxx_builtin_include_directories.extend([
            _join(sysroot_prefix, "/include"),
            _join(sysroot_prefix, "/usr/include"),
            _join(sysroot_prefix, "/usr/local/include"),
        ])

    cxx_builtin_include_directories = [
        dir
        for dir in cxx_builtin_include_directories
        if _is_hermetic_or_exists(rctx, dir, sysroot_path)
    ]
    print(cxx_builtin_include_directories)

    target_arch = rctx.attr.arch
    target_system_name = "aarch64-linux"

    ##target_system_name= "armeabi-linux"
    ##target_system_name= "armv7a-linux"
    ##target_system_name= "armv7-linux"
    link_flags = [
        "-L{}lib".format(toolchain_path_prefix),
        "-B{}bin".format(toolchain_path_prefix),
        "-lm",
        "-lstdc++",
        "-no-canonical-prefixes",
        "-Wl,--build-id=md5",
        "-Wl,--hash-style=gnu",
        "-Wl,-z,relro,-z,now",
    ]
    compiler_configuration = dict()
    if rctx.attr.compile_flags and len(rctx.attr.compile_flags) != 0:
        compiler_configuration["compile_flags"] = _list_to_string(rctx.attr.compile_flags)
    if rctx.attr.cxx_flags and len(rctx.attr.cxx_flags) != 0:
        compiler_configuration["cxx_flags"] = _list_to_string(rctx.attr.cxx_flags)
    if rctx.attr.link_flags and len(rctx.attr.link_flags) != 0:
        link_flags.extend(rctx.attr.link_flags)
    if len(link_flags) != 0:
        compiler_configuration["link_flags"] = _list_to_string(link_flags)
    if rctx.attr.archive_flags and len(rctx.attr.archive_flags) != 0:
        compiler_configuration["archive_flags"] = _list_to_string(rctx.attr.archive_flags)
    if rctx.attr.link_libs and len(rctx.attr.link_libs) != 0:
        compiler_configuration["link_libs"] = _list_to_string(rctx.attr.link_libs)
    if rctx.attr.opt_compile_flags and len(rctx.attr.opt_compile_flags) != 0:
        compiler_configuration["opt_compile_flags"] = _list_to_string(rctx.attr.opt_compile_flags)
    if rctx.attr.opt_link_flags and len(rctx.attr.opt_link_flags) != 0:
        compiler_configuration["opt_link_flags"] = _list_to_string(rctx.attr.opt_link_flags)
    if rctx.attr.dbg_compile_flags and len(rctx.attr.dbg_compile_flags) != 0:
        compiler_configuration["dbg_compile_flags"] = _list_to_string(rctx.attr.dbg_compile_flags)
    if rctx.attr.coverage_compile_flags and len(rctx.attr.coverage_compile_flags) != 0:
        compiler_configuration["coverage_compile_flags"] = _list_to_string(rctx.attr.coverage_compile_flags)
    if rctx.attr.coverage_link_flags and len(rctx.attr.coverage_link_flags) != 0:
        compiler_configuration["coverage_link_flags"] = _list_to_string(rctx.attr.coverage_link_flags)
    if rctx.attr.unfiltered_compile_flags and len(rctx.attr.unfiltered_compile_flags) != 0:
        compiler_configuration["unfiltered_compile_flags"] = _list_to_string(rctx.attr.unfiltered_compile_flags)

    print(compiler_configuration)
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
        Label("//toolchain:cc_wrapper.sh.tpl"),
        {
            "%{toolchain_path_prefix}": toolchain_path_prefix,
            "%{gcc_name}": rctx.attr.tool_names["gcc"],
        },
    )

    rctx.template(
        "BUILD.bazel",
        Label("//toolchain:openwrt_cc_toolchain_config.BUILD.tpl"),
        {
            "%{suffix}": suffix,
            "%{target_system_name}": target_system_name,
            "%{cc_toolchain_config_bzl}": str(cc_toolchain_config_bzl),
            "%{target_os_bzl}": "linux",
            "%{sysroot_label_str}": sysroot_label_str,
            "%{extra_compiler_files}": extra_compiler_files,
            "%{sysroot_path}": sysroot_path,
            "%{toolchain_path_prefix}": toolchain_path_prefix,
            "%{cxx_builtin_include_directories}": _list_to_string(cxx_builtin_include_directories),
            "%{symlinked_tools}": symlinked_tools,
            "%{compiler_configuration}": _dict_to_string(compiler_configuration),
            "%{target_arch}": target_arch,
            "%{tool_paths}": _dict_to_string(tool_paths),
        },
    )
    #_generate_build_file(rctx)
