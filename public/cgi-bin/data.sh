#!/bin/sh
printf "Content-Type: application/json\r\n\r\n"
ROOT="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
python3 - "$ROOT" <<'PY'
import csv
import json
import os
import sys

root = sys.argv[1]

def read_csv(name):
    path = os.path.join(root, "data", name)
    with open(path, newline="", encoding="utf-8-sig") as csv_file:
        return list(csv.DictReader(csv_file))

try:
    books = read_csv("books.csv")
    transactions = read_csv("circulation.csv")

    issued_by_book = {}
    for transaction in transactions:
        status = (transaction.get("Status") or "").strip().lower()
        if status == "returned":
            continue
        book_id = (transaction.get("Book_ID") or "").strip()
        if book_id:
            issued_by_book[book_id] = issued_by_book.get(book_id, 0) + 1

    rows = []
    category_counts = {}
    total_copies = 0
    for book in books:
        book_id = (book.get("Book_ID") or "").strip()
        category = (book.get("Category") or "").strip()
        copies = int(book.get("Total_Copies") or 0)
        issued = issued_by_book.get(book_id, 0)
        total_copies += copies
        rows.append({
            "Book_ID": book_id,
            "Title": book.get("Title") or "",
            "Author": book.get("Author") or "",
            "Category": category,
            "Total_Copies": copies,
            "Issued_Copies": issued,
            "Available_Copies": max(copies - issued, 0),
        })
        category_counts[category] = category_counts.get(category, 0) + 1

    response = {
        "title": "Library Book and Circulation Management Dashboard",
        "mode": "library",
        "cards": [
            ["Book Titles", len(books)],
            ["Total Copies", total_copies],
            ["Categories", len(category_counts)],
            ["Issued", sum(issued_by_book.values())],
        ],
        "rows": rows,
        "labels": list(category_counts),
        "values": list(category_counts.values()),
        "headers": [
            "Book_ID", "Title", "Author", "Category", "Total_Copies",
            "Issued_Copies", "Available_Copies",
        ],
    }
except (OSError, csv.Error, ValueError) as error:
    response = {
        "title": "Library Book and Circulation Management Dashboard",
        "mode": "library",
        "cards": [],
        "rows": [],
        "labels": [],
        "values": [],
        "error": str(error),
    }

print(json.dumps(response))
PY
