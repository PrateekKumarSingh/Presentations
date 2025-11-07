import os

import azure.identity
import dotenv
import openai


def format_movie(movie):
    return (
        f"Title: {movie['title']}\nYear: {movie['year']}\nGenres: {', '.join(movie['genres'])}\nPlot: {movie['plot']}"
    )


def get_title(m):
    if isinstance(m, dict):
        return m.get("title") or m.get("Title") or str(m)
    return str(m)


def get_meta(m):
    if isinstance(m, dict):
        year = m.get("year", "")
        genres = m.get("genres", "")
        if isinstance(genres, list):
            genres = ", ".join(genres)
        return year, genres
    return "", ""
