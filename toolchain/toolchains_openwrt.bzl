load(
    "//toolchain:common.bzl",
    _is_absolute_path = "is_absolute_path",
)
load(
    "//toolchain:openwrt_toolchain_config_impl.bzl",
    _openwrt_toolchain_config_impl = "openwrt_toolchain_config_impl",
)
load(
    "//toolchain:openwrt_toolchain_repo_impl.bzl",
    _openwrt_toolchain_repo_impl = "openwrt_toolchain_repo_impl",
)

_attrs = {
    "chip_model": attr.string(
        mandatory = True,
    ),
    "chip_version": attr.string(
        mandatory = True,
    ),
    "arch": attr.string(
        mandatory = True,
    ),
    "url": attr.string(
        mandatory = True,
    ),
    "sha256sum": attr.string(
        mandatory = True,
    ),
    "toolchain_prefix": attr.string(
        mandatory = False,
        default = "toolchain-aarch64_generic_gcc-12.3.0_musl",
    ),
    "tool_names": attr.string_dict(
        mandatory = False,
        default = {
            "ar": "aarch64-openwrt-linux-musl-ar",
            "ld": "aarch64-openwrt-linux-musl-ld.bin",
            "llvm-cov": "aarch64-openwrt-linux-musl-gcov.bin",
            "gcov": "aarch64-openwrt-linux-musl-gcov.bin",
            "cpp": "aarch64-openwrt-linux-musl-cpp.bin",
            "gcc": "aarch64-openwrt-linux-musl-gcc.bin",
            "nm": "aarch64-openwrt-linux-musl-nm.bin",
            "objcopy": "aarch64-openwrt-linux-musl-objcopy.bin",
            "objdump": "aarch64-openwrt-linux-musl-objdump.bin",
            "strip": "aarch64-openwrt-linux-musl-strip.bin",
        },
    ),
    "sysroot": attr.string(
        mandatory = False,
    ),
    "extra_compiler_files": attr.label(
        mandatory = False,
    ),
    "compile_flags": attr.string_list(
        mandatory = False,
    ),
    "cxx_flags": attr.string_list(
        mandatory = False,
    ),
    "link_flags": attr.string_list(
        mandatory = False,
    ),
    "archive_flags": attr.string_list(
        mandatory = False,
    ),
    "link_libs": attr.string_list(
        mandatory = False,
    ),
    "opt_compile_flags": attr.string_list(
        mandatory = False,
    ),
    "opt_link_flags": attr.string_list(
        mandatory = False,
    ),
    "dbg_compile_flags": attr.string_list(
        mandatory = False,
    ),
    "coverage_compile_flags": attr.string_list(
        mandatory = False,
    ),
    "coverage_link_flags": attr.string_list(
        mandatory = False,
    ),
    "unfiltered_compile_flags": attr.string_list(
        mandatory = False,
    ),
}

openwrt_toolchain_repo = repository_rule(
    attrs = _attrs,
    local = False,
    implementation = _openwrt_toolchain_repo_impl,
)

openwrt_toolchain_config = repository_rule(
    attrs = _attrs,
    local = True,
    configure = True,
    implementation = _openwrt_toolchain_config_impl,
)

def openwrt_toolchain_setup(name, **kwargs):
    if not kwargs.get("toolchains"):
        fail("must set toolchains")
    toolchains = kwargs.get("toolchains")
    aargs = dict()
    for chip_model, chip_model_info in toolchains.items():
        for chip_version, chip_version_info in chip_model_info.items():
            if not chip_version_info.get("url"):
                fail("must have url")
            if not chip_version_info.get("arch"):
                fail("must have arch")
            if not _is_absolute_path(chip_version_info.get("url")) and not chip_version_info.get("sha256sum"):
                fail("must have sha256sum unless url is a absolute path")

            aargs["chip_model"] = chip_model
            aargs["chip_version"] = chip_version
            aargs["url"] = chip_version_info.get("url")
            aargs["arch"] = chip_version_info.get("arch")
            aargs["sha256sum"] = chip_version_info.get("sha256sum")
            aargs["toolchain_prefix"] = chip_version_info.get("toolchain_prefix")
            aargs["tool_names"] = chip_version_info.get("tool_names")
            aargs["sysroot"] = chip_version_info.get("sysroot")
            aargs["extra_compiler_files"] = chip_version_info.get("extra_compiler_files")
            aargs["compile_flags"] = chip_version_info.get("compile_flags")
            aargs["cxx_flags"] = chip_version_info.get("cxx_flags")
            aargs["link_flags"] = chip_version_info.get("link_flags")
            aargs["archive_flags"] = chip_version_info.get("archive_flags")
            aargs["link_libs"] = chip_version_info.get("link_libs")
            aargs["opt_compile_flags"] = chip_version_info.get("opt_compile_flags")
            aargs["opt_link_flags"] = chip_version_info.get("opt_link_flags")
            aargs["dbg_compile_flags"] = chip_version_info.get("dbg_compile_flags")
            aargs["coverage_compile_flags"] = chip_version_info.get("coverage_compile_flags")
            aargs["coverage_link_flags"] = chip_version_info.get("coverage_link_flags")
            aargs["unfiltered_compile_flags"] = chip_version_info.get("unfiltered_compile_flags")
            openwrt_toolchain_repo(name = "openwrt_toolchain_repo_{}_{}".format(chip_model, chip_version), **aargs)
            openwrt_toolchain_config(name = "openwrt_toolchain_config_{}_{}".format(chip_model, chip_version), **aargs)
