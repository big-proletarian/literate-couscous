#!/usr/bin/env python3

from __future__ import annotations

import argparse
import math
from dataclasses import dataclass

import numpy as np
from sklearn.manifold import MDS

from analysis import QuizModel

WIDTH = 3000
HEIGHT = 2000
PADDING = 300

# Adjust these to taste
EDGE_PERCENTILE = 15
LABEL_FONT_SIZE = 14
NODE_RADIUS = 4

COLOURS = {
    "Marxism-Leninism": "#c62828",
    "Trotskyism (Orthodox)": "#d32f2f",
    "Trotskyism (Cliffite)": "#e53935",
    "Trotskyism (Shachtmanite)": "#ef5350",
    "Left-Communism (Bordigist)": "#b71c1c",
    "Left-Communism (ICT)": "#ad1457",
    "Council Communism": "#880e4f",
    "Communisation": "#6a1b9a",
    "Autonomism": "#4a148c",
    "Democratic Socialism": "#fb8c00",
    "Social Democracy": "#f57c00",
    "Anarcho-Communism": "#8e24aa",
    "Mutualism": "#5e35b1",
    "Collectivist Anarchism": "#7b1fa2",
    "Individualist Anarchism": "#512da8",
    "Liberalism": "#1976d2",
    "Social Liberalism": "#1e88e5",
    "Neoliberalism": "#1565c0",
    "Conservatism": "#455a64",
    "Christian Democracy": "#546e7a",
    "Fascism": "#212121",
    "National Bolshevism": "#000000",
}


@dataclass(slots=True)
class Graph:
    names: list[str]
    distances: np.ndarray
    coords: np.ndarray


def flatten_ideology(ideology: dict) -> np.ndarray:
    values = []

    for axis in ("a1", "a2", "a3", "a4", "a5", "a6", "a8"):
        values.extend(ideology[axis])

    values.append(ideology["a7"])

    return np.asarray(values, dtype=float)


def ideology_distance_matrix(model: QuizModel) -> tuple[list[str], np.ndarray]:
    names = list(model.ideologies)

    X = np.vstack([flatten_ideology(model.ideologies[name]) for name in names])

    D = np.linalg.norm(
        X[:, None, :] - X[None, :, :],
        axis=2,
    )

    return names, D


def answer_distance_matrix(model: QuizModel) -> tuple[list[str], np.ndarray]:
    names = list(model.ideologies)

    print("Computing optimal answer sets...")

    answers = []

    for name in names:
        print(f"  {name}")
        answers.append(
            np.asarray(
                model.optimise(model.ideologies[name]),
                dtype=float,
            )
        )

    X = np.vstack(answers)

    D = np.linalg.norm(
        X[:, None, :] - X[None, :, :],
        axis=2,
    )

    return names, D


def mds_embed(distances: np.ndarray) -> np.ndarray:
    return MDS(
        n_components=2,
        dissimilarity="precomputed",
        normalized_stress="auto",
        random_state=42,
    ).fit_transform(distances)


def repel_labels(
    coords: np.ndarray,
    iterations: int = 300,
    min_distance: float = 0.08,
) -> np.ndarray:
    coords = coords.copy()

    for _ in range(iterations):
        for i in range(len(coords)):
            for j in range(i + 1, len(coords)):
                dx = coords[j, 0] - coords[i, 0]
                dy = coords[j, 1] - coords[i, 1]

                dist = math.hypot(dx, dy)

                if dist >= min_distance:
                    continue

                if dist == 0:
                    dx = 0.001
                    dy = 0.001
                    dist = 0.001

                push = (min_distance - dist) * 0.5

                coords[i, 0] -= dx / dist * push
                coords[i, 1] -= dy / dist * push

                coords[j, 0] += dx / dist * push
                coords[j, 1] += dy / dist * push

    return coords


def normalise(coords: np.ndarray) -> np.ndarray:
    coords = coords.copy()

    mins = coords.min(axis=0)
    maxs = coords.max(axis=0)

    span = np.maximum(maxs - mins, 1e-9)

    coords = (coords - mins) / span

    coords[:, 0] *= WIDTH - 2 * PADDING
    coords[:, 1] *= HEIGHT - 2 * PADDING

    coords += PADDING

    return coords


def build_graph(
    names: list[str],
    distances: np.ndarray,
) -> Graph:

    coords = mds_embed(distances)
    coords = repel_labels(coords)

    return Graph(
        names=names,
        distances=distances,
        coords=coords,
    )


def write_svg(
    filename: str,
    title: str,
    graph: Graph,
) -> None:

    coords = normalise(graph.coords)

    non_zero = graph.distances[graph.distances > 0]

    threshold = np.percentile(
        non_zero,
        EDGE_PERCENTILE,
    )

    edge_count = 0

    with open(filename, "w", encoding="utf8") as f:
        f.write(
            f'<svg xmlns="http://www.w3.org/2000/svg" '
            f'width="{WIDTH}" '
            f'height="{HEIGHT}">\n'
        )

        f.write('<rect width="100%" height="100%" fill="white"/>\n')

        f.write(
            f"<text "
            f'x="50" '
            f'y="50" '
            f'font-size="32" '
            f'font-family="sans-serif">'
            f"{title}"
            f"</text>\n"
        )

        for i in range(len(graph.names)):
            for j in range(i + 1, len(graph.names)):
                if graph.distances[i, j] > threshold:
                    continue

                x1, y1 = coords[i]
                x2, y2 = coords[j]

                edge_count += 1

                f.write(
                    f"<line "
                    f'x1="{x1}" '
                    f'y1="{y1}" '
                    f'x2="{x2}" '
                    f'y2="{y2}" '
                    f'stroke="#d0d0d0" '
                    f'stroke-width="1"/>\n'
                )

        for name, (x, y) in zip(
            graph.names,
            coords,
        ):
            colour = COLOURS.get(
                name,
                "#222222",
            )

            f.write(f'<circle cx="{x}" cy="{y}" r="{NODE_RADIUS}" fill="{colour}" />\n')

            f.write(
                f"<text "
                f'x="{x + 8}" '
                f'y="{y + 4}" '
                f'font-size="{LABEL_FONT_SIZE}" '
                f'font-family="sans-serif" '
                f'fill="{colour}">'
                f"{name}"
                f"</text>\n"
            )

        f.write("</svg>\n")

    print(f"Wrote {filename} ({len(graph.names)} nodes, {edge_count} edges)")


def ideology_space() -> None:
    model = QuizModel()

    names, distances = ideology_distance_matrix(model)

    graph = build_graph(
        names,
        distances,
    )

    write_svg(
        "ideology_space.svg",
        "Ideology Space",
        graph,
    )


def answer_space() -> None:
    model = QuizModel()

    names, distances = answer_distance_matrix(model)

    graph = build_graph(
        names,
        distances,
    )

    write_svg(
        "answer_space.svg",
        "Answer Space (Optimal Answers)",
        graph,
    )


def main() -> None:
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "mode",
        choices=[
            "ideology-space",
            "answer-space",
        ],
    )

    args = parser.parse_args()

    if args.mode == "ideology-space":
        ideology_space()
    else:
        answer_space()


if __name__ == "__main__":
    main()
