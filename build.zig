const std = @import("std");
const microzig = @import("microzig");

const MicroBuild = microzig.MicroBuild(.{
    .rp2xxx = true,
});

pub fn build(b: *std.Build) void {
    const mz_dep = b.dependency("microzig", .{});
    const mb = MicroBuild.init(b, mz_dep) orelse return;

    const pico_board = mb.ports.rp2xxx.boards.raspberrypi.pico.board orelse return;
    const target = mb.ports.rp2xxx.chips.rp2040.derive(.{
        .board = .{
            .name = "XIAO RP2040",
            .root_source_file = b.path("boards/xiao_rp2040.zig"),
            .imports = pico_board.imports,
        },
    });

    const firmware = mb.add_firmware(.{
        .name = "main",
        .target = target,
        .optimize = .ReleaseSmall,
        .root_source_file = b.path("src/main.zig"),
    });

    mb.install_firmware(firmware, .{});

    const flash_cmd = b.addSystemCommand(&[_][]const u8{
        "picotool",
        "load",
        "-f",
    });
    flash_cmd.addFileArg(firmware.get_emitted_bin(null));
    flash_cmd.step.dependOn(&firmware.artifact.step);

    const flash_step = b.step("flash", "Flash firmware using picotool");
    flash_step.dependOn(&flash_cmd.step);
}
