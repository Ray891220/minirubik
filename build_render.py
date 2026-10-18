#!/usr/bin/env python3
"""Generate separate Ripes GUI/CLI assembly from one existing minirubik source.

Use from the minirubik project directory:
    python3 build_render.py

The generated GUI version is an unchanged copy of stage4_led_final.s.
The CLI version uses a minimal already-existing solver harness, and removes
only the trailing draw_cube / draw_sticker routines. No source files are
modified by this script.

Because this Ripes assembler does not support GNU .if, this is a build-time
switch implemented by the host Python script, not an assembler .if switch.
"""

from pathlib import Path
import argparse
import re
import sys


def find_label(text: str, name: str) -> int:
    matches = list(re.finditer(rf'(?m)^{re.escape(name)}:[ \t]*(?:#.*)?$', text))
    if len(matches) != 1:
        raise ValueError(f'Expected exactly one {name}: label, found {len(matches)}')
    return matches[0].start()


def build_cli(source: str) -> str:
    # The project version supplied by the student has all demo logic in
    # main: ... rank_orientation: and places renderer routines at the end.
    main_pos = find_label(source, 'main')
    rank_pos = find_label(source, 'rank_orientation')
    renderer_pos = find_label(source, 'draw_cube')
    sticker_pos = find_label(source, 'draw_sticker')
    if not (main_pos < rank_pos < renderer_pos < sticker_pos):
        raise ValueError('Unexpected source layout: not safe to generate CLI')

    main_block = source[main_pos:rank_pos]
    if 'jal  ra, solve' not in main_block and not re.search(
            r'\bjal\s+ra\s*,\s*solve\b', main_block):
        raise ValueError('The original main block has no solve() call')
    if len(re.findall(r'\bjal\s+ra\s*,\s*draw_cube\b', main_block)) != 3:
        raise ValueError('Expected 3 draw_cube calls in main, source changed')

    tail = source[renderer_pos:]
    # Refuse to discard any data definition that might live after renderer.
    if re.search(r'(?m)^\s*(?:\.data|\.bss|\.rodata|\.section|\.include)\b', tail):
        raise ValueError('Data/section directives after draw_cube:; inspect file manually')
    # Use the same interface as the already tested stage3_solver_test.S.
    # a0=1 on success and a1=solution length; exit through Ripes ecall 10.
    solver_main = '''main:
    # CLI mode: renderer excluded; measure only the solver.
    la   a0, state
    jal  ra, solve

cli_done:
    li   a7, 10
    ecall

'''
    cli = source[:main_pos] + solver_main + source[rank_pos:renderer_pos]
    for raw in cli.splitlines():
        line = raw.partition('#')[0]
        if re.search(r'LED_MATRIX_0_(?:BASE|WIDTH|HEIGHT)', line):
            raise ValueError('CLI still references LED Matrix symbols in code')
        if re.search(r'\b(?:jal|j)\s+(?:ra\s*,\s*)?draw_(?:cube|sticker)\b', line):
            raise ValueError('CLI still refers to removed renderer routines')
    return cli


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', default='stage4_led_final.s')
    parser.add_argument('--gui', default='stage4_gui.s')
    parser.add_argument('--cli', default='stage4_cli.s')
    args = parser.parse_args()
    src, gui, cli = (Path(v) for v in (args.source, args.gui, args.cli))
    if not src.is_file():
        parser.error(f'Missing source: {src}')
    if len({p.resolve() for p in (src, gui, cli)}) != 3:
        parser.error('Source and output paths must be different')
    source = src.read_text(encoding='utf-8')
    try:
        cli_text = build_cli(source)
    except ValueError as exc:
        parser.error(str(exc))
    gui.write_text(source, encoding='utf-8')
    cli.write_text(cli_text, encoding='utf-8')
    print(f'GUI: {gui} (byte-for-byte equivalent to source text)')
    print(f'CLI: {cli} (solver-only entry point; renderer functions removed)')
    print('Next: GUI assemble with LED 35x25; CLI measure with RV32_ISS --iret.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
