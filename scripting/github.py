import os
import csv
import requests

TOKEN = os.environ["GITHUB_TOKEN"]
API = "https://api.github.com"

headers = {
    "Authorization": f"Bearer {TOKEN}",
    "Accept": "application/vnd.github+json",
    "X-Github-Api-Version": "2022-11-28",
}

with open("repos.txt", encoding="utf-8") as f:
    repos = [
        line.strip()
        for line in f
        if line.strip() and not line.strip().startswith("#")
    ]

rows = []

for repo in repos:
    url = f"{API}/repos/{repo}/pulls"
    params = {
        "state" = "all",
        "sort" = "updated",
        "direction" = "desc",
        "per_page" = 10,
    }

    try:
        response = requests.get(url, params=params, headers=headers, timeout = 30)
        response.raise_for_status()
        for pr in response.json():
            rows.append({
                "repository": repo,
                "number": pr["number"],
                "title": pr["title"],
                "state": pr["state"],
                "author": pr["user"]["login"],
                "created_at": pr["created_at"],
                "updated_at": pr["updated_at"],
                "merged_at": pr["merged_at"],
                "url": pr["html_url"],
            })
            
        print(f"success:{repo}")

    except requests.RequestException as exec:
        print(f"ERROR: {repo}: {exec}")

fields = [
    "repository", "number", "title", "state", "author",
    "created_at", "updated_at", "merged_at", "url"
]

with open("github_pr_report.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=fields)
    writer.writeheader()
    writer.writerows(rows)

print(f"Saved {len(rows)} PRs to github_pr_report.csv")



-------------------------------------------------------stage 2 ------------------------------------------
import os
import csv
import logging
import requests

from concurrent.futures import ThreadPoolExecutor, as_completed
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry


API = "https://api.github.com"
TOKEN = os.getenv("GITHUB_TOKEN")

MAX_WORKERS = 5
MAX_RETRIES = 3
PER_PAGE = 10

if not TOKEN:
    raise RuntimeError("GITHUB_TOKEN environment variable is missing")


# -------------------------------
# 1. Configure logging
# -------------------------------

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s: %(message)s",
    handlers=[
        logging.FileHandler("github_automation.log"),
        logging.StreamHandler()
    ]
)


# -------------------------------
# 2. Configure HTTP session
# -------------------------------

def create_session():

    session = requests.Session()

    retry = Retry(
        total=MAX_RETRIES,
        backoff_factor=1,
        status_forcelist=[429, 500, 502, 503, 504],
        allowed_methods=["GET"],
        respect_retry_after_header=True
    )

    adapter = HTTPAdapter(max_retries=retry)

    session.mount("https://", adapter)

    session.headers.update({
        "Authorization": f"Bearer {TOKEN}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28"
    })

    return session


# -------------------------------
# 3. Read repositories
# -------------------------------

def load_repositories():

    with open("repos.txt", encoding="utf-8") as file:

        repos = [
            line.strip()
            for line in file
            if line.strip() and not line.strip().startswith("#")
        ]

    # Remove duplicates while preserving order
    repos = list(dict.fromkeys(repos))

    # Validate repository format
    for repo in repos:
        if repo.count("/") != 1:
            raise ValueError(f"Invalid repository format: {repo}")

    return repos


# -------------------------------
# 4. Fetch PRs from one repository
# -------------------------------

def fetch_prs(repo):

    url = f"{API}/repos/{repo}/pulls"

    params = {
        "state": "all",
        "sort": "updated",
        "direction": "desc",
        "per_page": PER_PAGE
    }

    try:

        # Each worker gets its own session
        with create_session() as session:

            response = session.get(
                url,
                params=params,
                timeout=(5, 30)
            )

            response.raise_for_status()

            prs = response.json()

            if not isinstance(prs, list):
                raise ValueError("Unexpected GitHub API response")

            records = []

            for pr in prs:

                records.append({
                    "repository": repo,
                    "number": pr["number"],
                    "title": pr["title"],
                    "state": pr["state"],
                    "author": pr["user"]["login"],
                    "created_at": pr["created_at"],
                    "updated_at": pr["updated_at"],
                    "merged_at": pr["merged_at"],
                    "url": pr["html_url"]
                })

        logging.info("SUCCESS: %s - %s PRs", repo, len(records))

        return records, None

    except (requests.RequestException, ValueError, KeyError, TypeError) as exc:

        logging.error("FAILED: %s - %s", repo, exc)

        return [], {
            "repository": repo,
            "error": str(exc)
        }


# -------------------------------
# 5. Process all repositories
# -------------------------------

def process_repositories(repos):

    all_prs = []
    errors = []

    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:

        futures = {
            executor.submit(fetch_prs, repo): repo
            for repo in repos
        }

        for future in as_completed(futures):

            repo = futures[future]

            try:

                records, error = future.result()

                all_prs.extend(records)

                if error:
                    errors.append(error)

            except Exception as exc:

                logging.exception("Unexpected error: %s", repo)

                errors.append({
                    "repository": repo,
                    "error": str(exc)
                })

    return all_prs, errors


# -------------------------------
# 6. Generate CSV report
# -------------------------------

def write_report(filename, rows, fields):

    with open(
        filename,
        "w",
        newline="",
        encoding="utf-8"
    ) as file:

        writer = csv.DictWriter(
            file,
            fieldnames=fields
        )

        writer.writeheader()
        writer.writerows(rows)


# -------------------------------
# 7. Main execution
# -------------------------------

def main():

    repos = load_repositories()

    logging.info("Processing %s repositories", len(repos))

    prs, errors = process_repositories(repos)

    pr_fields = [
        "repository",
        "number",
        "title",
        "state",
        "author",
        "created_at",
        "updated_at",
        "merged_at",
        "url"
    ]

    error_fields = ["repository", "error"]

    write_report(
        "github_pr_report.csv",
        prs,
        pr_fields
    )

    write_report(
        "github_pr_errors.csv",
        errors,
        error_fields
    )

    logging.info("Total PRs collected: %s", len(prs))
    logging.info("Failed repositories: %s", len(errors))
    logging.info("Reports generated successfully")


if __name__ == "__main__":
    main()


------------------------------------------------stage 3 ------------------------------------------------

