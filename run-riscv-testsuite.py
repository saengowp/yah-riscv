#! /bin/python

import os
from os.path import isfile, join
import subprocess

test_path = "riscv-testsuite/"
print("Starting Test")
for f in os.listdir(test_path):
    p = join(test_path, f)
    if not isfile(p):
        continue
    if p[-4:] == 'dump':
        continue
    print("Found test ", f)
    passed_section = False
    passed_addr = None
    with open(p + ".dump", "r") as ff:
        for line in ff.readlines():
            if "<pass>:" in line:
                passed_section = True
            if passed_section and "ecall" in line:
                [addr, _, _] = line.split()
                passed_addr = addr[:-1]
                break
    if not passed_addr:
        print("Error can't detect passed addr, skipping")
        continue
    print("Compiling ROM")
    p = subprocess.run(["riscv32-unknown-elf-elf2hex", "--input", p, "--bit-width", "32", "--output", "./rom.vh"])
    if p.returncode != 0:
        print("Compile error SKIPPING")
        continue
    p = subprocess.run(["./a.out"], capture_output=True, encoding="ascii")
    actual_addr = None
    for line in p.stdout.split("\n"):
        if "ECALL" in line:
            actual_addr = line.split()[2]
            break
    if not actual_addr:
        print("Failed to detect ECALL", p.stdout)
        break
    print("Expect ECALL at {}. Actual ECALL at {}. Verdict: {}".format(passed_addr, actual_addr, "PASSED" if passed_addr == actual_addr[-len(passed_addr):] else "FAILED")) 
