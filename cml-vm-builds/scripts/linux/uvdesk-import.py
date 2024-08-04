#!/usr/bin/python3
import csv
import requests
import sys
import urllib3
from requests.auth import HTTPBasicAuth

urllib3.disable_warnings()

URL = "https://localhost"
session = requests.Session()
session.verify = False
auth_response = session.post(f"{URL}/api/v1/session/login", auth=HTTPBasicAuth('admin@wsc2024.local', 'AllTooWell13@')).json()
session.headers = {"Authorization": f"Basic {auth_response['accessToken']}"}

support_group_to_create = set()
groups = {}

with open(sys.argv[1], newline='') as csvfile:
    user_reader = list(csv.DictReader(csvfile, delimiter=','))

with open(sys.argv[2]) as csvfile:
    tickets = list(csv.DictReader(csvfile, delimiter=','))

# Create set of group names
for row in user_reader:
    support_group_to_create.add(row["groupname"])

# Create groups
for group in support_group_to_create:
    groups_res = session.post(f"{URL}/api/v1/groups/create", data={
       "name": group,
       "description": f"WSC2024 Support group {group}",
       "isActive": True,
    })

# Create group lookup
all_groups_found = False
page = 1
while (not all_groups_found):
    res = session.get(f"{URL}/api/v1/groups?page={page}").json()
    for group in res["collection"]["groups"]:
        groups[group["name"]] = group
    if "next" not in res["collection"]["pagination_data"]:
        all_groups_found = True
    else:
        page = res["collection"]["pagination_data"]["next"]

# Create agents
for row in user_reader:
    agents_res = session.post(f"{URL}/api/v1/agents/create", data={
        "email": row["email"],
        "firstName": row["role"].capitalize(),
        "lastName": row["groupname"],
        "password": row["password"],
        "contactNumber": "",
        "signature": "",
        "designation": "",
        "role": f"ROLE_AGENT",
        "isActive": True,
        "ticketView": "1" if row["role"] == "expert" else "2",
        "groups[]": groups[row["groupname"]]["id"],
        "agentPrivilege[]": 1
    })

# Build agent lookup table
all_agents = session.get(f"{URL}/api/v1/agents").json()
agents = {}
for agent in all_agents["collection"]:
    agents[agent["email"]] = agent

# Create ticket for each competitor
for row in user_reader:
    if row["role"] == "competitor":
        for ticket in tickets:
            ticket_res = session.post(f"{URL}/api/v1/ticket", json={
                "from": ticket["from"],
                "name": ticket["name"],
                "subject": ticket["subject"],
                "message": ticket["message"],
                "actAsType": "customer",
            }).json()
            ticket_id = ticket_res["ticketId"]
            session.patch(f"{URL}/api/v1/ticket/{ticket_id}", json={
                "property": "group",
                "value": groups[row["groupname"]]["id"]
            })
            session.put(f"{URL}/api/v1/ticket/{ticket_id}/agent", json={
                "id": agents[row["email"]]["id"],
            })