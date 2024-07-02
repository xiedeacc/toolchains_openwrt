load(
    "//toolchain:common.bzl",
    _download_openwrt = "download_openwrt",
    _is_absolute_path = "is_absolute_path",
)

def openwrt_toolchain_repo_impl(rctx):
    print(rctx.attr)
    rctx.file(
        "BUILD.bazel",
        content = rctx.read(Label("//toolchain:BUILD.openwrt_repo")),
        executable = False,
    )
    if _is_absolute_path(rctx.attr.url):
        return rctx.aatr

    updated_attrs = _download_openwrt(rctx)
    return updated_attrs
