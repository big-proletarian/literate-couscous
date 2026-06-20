#!/usr/bin/env python3

from __future__ import annotations

import argparse
import math
import random
import re
from collections import defaultdict
from pathlib import Path

AXES = ("a1", "a2", "a3", "a4", "a5", "a6", "a8")
ALL_KEYS = (
    "a1a",
    "a1b",
    "a1c",
    "a2a",
    "a2b",
    "a2c",
    "a3a",
    "a3b",
    "a3c",
    "a4a",
    "a4b",
    "a4c",
    "a5a",
    "a5b",
    "a5c",
    "a6a",
    "a6b",
    "a6c",
    "a7",
    "a8a",
    "a8b",
    "a8c",
)

MULTIPLIERS = (-1.0, -0.5, 0.0, 0.5, 1.0)


class QuizModel:
    def __init__(self, questions_file="questions.js", ideologies_file="ideologies.js"):

        self.questions = self._load_questions(
            Path(questions_file).read_text(encoding="utf8")
        )

        self.ideologies = self._load_ideologies(
            Path(ideologies_file).read_text(encoding="utf8")
        )

        self.max_scores = {k: 0.0 for k in ALL_KEYS}

        for q in self.questions:
            for k, v in q["targets"].items():
                self.max_scores[k] += abs(v)

    def _load_questions(self, text):
        result = []

        pattern = re.compile(
            r'\{\s*text:\s*"(.*?)"\s*,\s*targets:\s*\{(.*?)\}\s*\}',
            re.S,
        )

        for text_, targets in pattern.findall(text):
            t = {}

            for key, value in re.findall(
                r"([a-z0-9]+)\s*:\s*(-?\d+(?:\.\d+)?)",
                targets,
            ):
                t[key] = float(value)

            result.append(
                {
                    "text": text_,
                    "targets": t,
                }
            )

        return result

    def _load_ideologies(self, text):

        result = {}

        pattern = re.compile(
            r'"([^"]+)":\s*\{(.*?)\}',
            re.S,
        )

        for name, body in pattern.findall(text):
            vec = {}

            for axis in AXES:
                m = re.search(
                    rf"{axis}\s*:\s*\[\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*\]",
                    body,
                )

                if m:
                    vec[axis] = [
                        float(m.group(1)),
                        float(m.group(2)),
                        float(m.group(3)),
                    ]

            m = re.search(r"a7\s*:\s*([\d.]+)", body)

            if m:
                vec["a7"] = float(m.group(1))

            if vec:
                result[name] = vec

        return result

    def profile(self, answers):

        scores = {k: 0.0 for k in ALL_KEYS}

        for answer, q in zip(answers, self.questions):
            for key, weight in q["targets"].items():
                scores[key] += answer * weight

        result = {}

        for axis in AXES:
            na = (
                (self.max_scores[f"{axis}a"] + scores[f"{axis}a"])
                / (2 * self.max_scores[f"{axis}a"])
                * 100
            )

            nb = (
                (self.max_scores[f"{axis}b"] + scores[f"{axis}b"])
                / (2 * self.max_scores[f"{axis}b"])
                * 100
            )

            nc = (
                (self.max_scores[f"{axis}c"] + scores[f"{axis}c"])
                / (2 * self.max_scores[f"{axis}c"])
                * 100
            )

            total = na + nb + nc

            if total == 0:
                na, nb, nc = 33.3, 33.3, 33.4
                total = 100

            pa = round(na / total * 100, 1)
            pb = round(nb / total * 100, 1)
            pc = round(100 - pa - pb, 1)

            result[axis] = [pa, pb, pc]

        result["a7"] = round(
            (self.max_scores["a7"] + scores["a7"]) / (2 * self.max_scores["a7"]) * 100,
            1,
        )

        return result

    @staticmethod
    def distance(profile, ideology):

        d = 0.0

        for axis in AXES:
            for i in range(3):
                d += (profile[axis][i] - ideology[axis][i]) ** 2

        d += (profile["a7"] - ideology["a7"]) ** 2

        return d

    def nearest(self, ideology_name, n=5):

        base = self.ideologies[ideology_name]

        rows = []

        for name, vec in self.ideologies.items():
            if name == ideology_name:
                continue

            rows.append(
                (
                    name,
                    round(
                        math.sqrt(self.distance(base, vec)),
                        1,
                    ),
                )
            )

        rows.sort(key=lambda x: x[1])

        return rows[:n]

    def optimise(self, target):

        answers = [0.0] * len(self.questions)

        for _ in range(3):
            for q in range(len(answers)):
                best_mult = 0.0
                best_dist = float("inf")

                for mult in MULTIPLIERS:
                    answers[q] = mult

                    profile = self.profile(answers)

                    d = self.distance(
                        profile,
                        target,
                    )

                    if d < best_dist:
                        best_dist = d
                        best_mult = mult

                answers[q] = best_mult

        return answers

    def monte_carlo(self, trials=100000):

        counts = defaultdict(int)

        for _ in range(trials):
            answers = [random.choice(MULTIPLIERS) for _ in self.questions]

            profile = self.profile(answers)

            winner = min(
                self.ideologies,
                key=lambda n: self.distance(
                    profile,
                    self.ideologies[n],
                ),
            )

            counts[winner] += 1

        return sorted(
            counts.items(),
            key=lambda x: x[1],
            reverse=True,
        )


def main():

    parser = argparse.ArgumentParser()

    sub = parser.add_subparsers(dest="cmd")

    p = sub.add_parser("nearest")
    p.add_argument("ideology")

    p = sub.add_parser("optimise")
    p.add_argument("ideology")

    p = sub.add_parser("attainability")
    p.add_argument("--trials", type=int, default=100000)

    args = parser.parse_args()

    model = QuizModel()

    if args.cmd == "nearest":
        for name, dist in model.nearest(args.ideology):
            print(f"{name}: {dist}")

    elif args.cmd == "optimise":
        answers = model.optimise(model.ideologies[args.ideology])

        labels = {
            1.0: "Strongly Agree",
            0.5: "Agree",
            0.0: "Neutral/Unsure",
            -0.5: "Disagree",
            -1.0: "Strongly Disagree",
        }

        for i, (q, a) in enumerate(
            zip(model.questions, answers),
            start=1,
        ):
            print(f"Q{i}: {q['text']}")
            print(f"-> {labels[a]}")
            print()

    elif args.cmd == "attainability":
        for name, count in model.monte_carlo(args.trials):
            pct = round(
                count / args.trials * 100,
                2,
            )
            print(f"{name}: {count} ({pct}%)")


if __name__ == "__main__":
    main()
