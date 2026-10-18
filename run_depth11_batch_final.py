#!/usr/bin/env python3
"""Measure all depth-11 minirubik inputs with Ripes RV32_ISS --iret.

Run from your minirubik repository directory. Does not modify the source.
First run: python3 run_depth11_batch.py --limit 10
Full run:  python3 run_depth11_batch.py
Successful rows are saved to depth11_iret_results.csv and reused on rerun.
"""
import argparse
import csv
import os
from pathlib import Path
import re
import subprocess
import tempfile
import time

RIPES = Path('/home/rayqiu/Applications/Ripes-v2.2.6-106-g5b8a616-linux-x86_64.AppImage')
SOURCE = Path('stage4_cli.s')
INPUT = Path('depth11_states_opt_order.txt')
OUTPUT = Path('depth11_iret_results_final.csv')
FIELDS = ['state', 'instructions', 'a0', 'a1', 'elapsed_seconds']
STATE_RE = re.compile(
    r'(?m)^(state:[ \t]*\n[ \t]*\.byte[ \t]+)[^\n]+'
    r'(\n[ \t]*\.byte[ \t]+)[^\n]+'
)


def replace_state(source, state):
    p = ', '.join(str(int(c) - 1) for c in state[:7])
    o = ', '.join(str(int(c) - 1) for c in state[7:])
    result, matches = STATE_RE.subn(lambda m: m.group(1) + p + m.group(2) + o,
                                    source, count=1)
    if matches != 1:
        raise ValueError('Could not find the two .byte lines after state: in stage3_solver_test.S')
    return result


def parse_ripes(output):
    retired = re.search(r'(?m)^===== instructions retired[ \t]*\n(\d+)[ \t]*$', output)
    x10 = re.search(r'(?m)^x10:[ \t]*(-?\d+)(?:[ \t]|$)', output)
    x11 = re.search(r'(?m)^x11:[ \t]*(-?\d+)(?:[ \t]|$)', output)
    exited = re.search(r'(?m)^Program exited with code:[ \t]*0[ \t]*$', output)
    if not (retired and x10 and x11 and exited):
        raise RuntimeError('Missing retired count, a0/a1 or successful exit in Ripes output:\n'
                           + output[-2000:])
    instructions, a0, a1 = int(retired.group(1)), int(x10.group(1)), int(x11.group(1))
    if (a0, a1) != (1, 11):
        raise RuntimeError(f'Unexpected solver result: a0={a0}, a1={a1}')
    return instructions, a0, a1


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--limit', type=int, default=None,
                        help='Process only the first N inputs (start with --limit 10)')
    parser.add_argument('--timeout', type=int, default=180,
                        help='Maximum seconds per Ripes process (default: 180)')
    args = parser.parse_args()
    if args.limit is not None and args.limit < 1:
        parser.error('--limit must be positive')
    for path in (RIPES, SOURCE, INPUT):
        if not path.is_file():
            parser.error(f'Missing file: {path}. Run in minirubik repository.')
    states = [s.strip() for s in INPUT.read_text(encoding='utf-8').splitlines() if s.strip()]
    if len(states) != 2644 or len(set(states)) != 2644:
        parser.error('Expected exactly 2,644 distinct states in depth11_states.txt')
    for s in states:
        if (len(s) != 14 or sorted(s[:7]) != list('1234567')
                or any(c not in '123' for c in s[7:])
                or sum(int(c) - 1 for c in s[7:]) % 3 != 0):
            parser.error(f'Invalid cube encoding: {s!r}')
    source = SOURCE.read_text(encoding='utf-8')
    replace_state(source, states[0])  # fail early if source format changed
    completed = {}
    if OUTPUT.exists():
        with OUTPUT.open(newline='', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            if reader.fieldnames != FIELDS:
                parser.error(f'{OUTPUT} has unexpected columns; move it aside first')
            for row in reader:
                if row['state'] in completed:
                    parser.error(f'Duplicate state in {OUTPUT}: {row["state"]}')
                completed[row['state']] = row
    selected = states[:args.limit] if args.limit else states
    env = os.environ.copy()
    env['QT_QPA_PLATFORM'] = 'xcb'
    temp_path = None
    try:
        # Keep temporary assembly in repository for consistent .include relative paths.
        with tempfile.NamedTemporaryFile('w', encoding='utf-8', suffix='.S',
                                         prefix='.depth11_batch_', dir='.',
                                         delete=False) as f:
            temp_path = Path(f.name)
        with OUTPUT.open('a', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=FIELDS)
            if f.tell() == 0:
                writer.writeheader()
                f.flush()
            for i, state in enumerate(selected, 1):
                if state in completed:
                    continue
                temp_path.write_text(replace_state(source, state), encoding='utf-8')
                started = time.perf_counter()
                try:
                    proc = subprocess.run(
                        [str(RIPES), '--mode', 'cli', '--src', str(temp_path),
                         '-t', 'asm', '--proc', 'RV32_ISS', '--iret', '--regs'],
                        env=env, text=True, stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT, timeout=args.timeout)
                except subprocess.TimeoutExpired:
                    raise RuntimeError(f'Ripes timed out on state {state} after {args.timeout}s')
                elapsed = time.perf_counter() - started
                if proc.returncode != 0:
                    raise RuntimeError(f'Ripes process failed on {state}:\n{proc.stdout[-2000:]}')
                try:
                    instructions, a0, a1 = parse_ripes(proc.stdout)
                except RuntimeError as e:
                    raise RuntimeError(f'State {state}: {e}') from e
                row = dict(state=state, instructions=instructions, a0=a0, a1=a1,
                           elapsed_seconds=f'{elapsed:.3f}')
                writer.writerow(row)
                f.flush()  # keep completed measurements safe if interrupted
                completed[state] = row
                if i % 10 == 0 or i == len(selected):
                    print(f'[{i}/{len(selected)}] last: {state}, retired={instructions:,}, '
                          f'elapsed={elapsed:.2f}s', flush=True)
    except KeyboardInterrupt:
        print('\nInterrupted. Rerun the script to resume saved results.')
        return 130
    finally:
        if temp_path is not None:
            temp_path.unlink(missing_ok=True)
    measured = [completed[s] for s in selected if s in completed]
    if measured:
        counts = [int(r['instructions']) for r in measured]
        worst = max(measured, key=lambda r: int(r['instructions']))
        print(f'Completed: {len(measured)}/{len(selected)}')
        print(f'Mean retired: {sum(counts)/len(counts):,.1f}')
        print(f'Max retired: {int(worst["instructions"]):,}, state={worst["state"]}')
        print(f'Over 50,000,000: {sum(n > 50_000_000 for n in counts)}')
        print(f'Saved: {OUTPUT}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
