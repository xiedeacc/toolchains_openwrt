# CC toolchain for gcc-%{suffix}.
package(default_visibility = ["//visibility:public"])

load("@bazel_skylib//rules:native_binary.bzl", "native_binary")
load("@rules_cc//cc:defs.bzl", "cc_toolchain", "cc_toolchain_suite")
load("@toolchains_llvm//toolchain/internal:system_module_map.bzl", "system_module_map")
load("%{cc_toolchain_config_bzl}", "cc_toolchain_config")

filegroup(name = "empty")

filegroup(
    name = "internal-use-symlinked-tools",
    srcs = [
        %{symlinked_tools}
    ],
    visibility = ["//visibility:private"],
)

filegroup(
    name = "internal-use-wrapped-tools",
    srcs = [
        "bin/cc_wrapper.sh",
    ],
    visibility = ["//visibility:private"],
)

filegroup(
    name = "internal-use-files",
    srcs = [
        ":internal-use-symlinked-tools",
        ":internal-use-wrapped-tools",
    ],
    visibility = ["//visibility:private"],
)

filegroup(
    name = "sysroot-components-%{suffix}",
    srcs = [
        %{sysroot_label_str}
    ],
)

filegroup(
    name = "compiler-components-%{suffix}",
    srcs = [
        ":sysroot-components-%{suffix}",
        %{extra_compiler_files}
    ],
)

filegroup(
    name = "linker-components-%{suffix}",
    srcs = [
        ":sysroot-components-%{suffix}",
    ],
)

filegroup(
    name = "all-components-%{suffix}",
    srcs = [
        ":compiler-components-%{suffix}",
        ":linker-components-%{suffix}",
    ],
)

filegroup(name = "all-files-%{suffix}", srcs = [":all-components-%{suffix}", ":internal-use-files"])
filegroup(name = "archiver-files-%{suffix}", srcs = [":internal-use-files"])
filegroup(name = "assembler-files-%{suffix}", srcs = [":internal-use-files"])
filegroup(name = "compiler-files-%{suffix}", srcs = [":compiler-components-%{suffix}", ":internal-use-files"])
filegroup(name = "linker-files-%{suffix}", srcs = [":linker-components-%{suffix}", ":internal-use-files"])
filegroup(name = "objcopy-files-%{suffix}", srcs = [":internal-use-files"])
filegroup(name = "strip-files-%{suffix}", srcs = [":internal-use-files"])

filegroup(
    name = "include-components-%{suffix}",
    srcs = [
        ":compiler-components-%{suffix}",
        ":sysroot-components-%{suffix}",
    ],
)

system_module_map(
    name = "module-%{suffix}",
    cxx_builtin_include_files = ":include-components-%{suffix}",
    cxx_builtin_include_directories = %{cxx_builtin_include_directories},
    sysroot_path = "%{sysroot_path}",
)

toolchain(
    name = "cc-toolchain-%{suffix}",
    exec_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:linux",
    ],
    target_compatible_with = [
        "@platforms//cpu:%{target_arch}",
        "@platforms//os:linux",
    ],
    toolchain = ":gcc-%{suffix}",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)

cc_toolchain(
    name = "gcc-%{suffix}",
    all_files = "all-files-%{suffix}",
    ar_files = "archiver-files-%{suffix}",
    as_files = "assembler-files-%{suffix}",
    compiler_files = "compiler-files-%{suffix}",
    linker_files = "linker-files-%{suffix}",
    objcopy_files = "objcopy-files-%{suffix}",
    strip_files = "strip-files-%{suffix}",
    toolchain_config = "local-%{suffix}",
    module_map = "module-%{suffix}",
    dwp_files = ":empty",
)

cc_toolchain_config(
    name = "local-%{suffix}",
    toolchain_identifier = "openwrt_toolchain_%{suffix}",
    target_system_name = "%{target_system_name}",
    tool_paths = %{tool_paths},
    compiler_configuration = %{compiler_configuration},
    sysroot_path = "%{sysroot_path}",
    cxx_builtin_include_directories = %{cxx_builtin_include_directories},
)
