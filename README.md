# Kyte — Organizational Hierarchy Visualizer

> A Flutter + Firebase app that maps, manages, and visualizes employee relationships in a clean, interactive tree structure.

---

## 🚀 Features

- **Interactive org tree** — Expand, collapse, and navigate your organization's hierarchy at a glance
- **Member profiles** — Create and manage employee records with role, department, and team info
- **Manager–employee mapping** — Define and reassign reporting relationships with ease
- **Smart search** — Find any employee instantly with auto-focus and node highlighting
- **Real-time sync** — Firestore listeners keep every connected device up to date, instantly
- **Subtree deletion** — Removing a member cascades cleanly through their reporting chain

---

## 🧩 Tech Stack

| Layer    | Technology              |
|----------|-------------------------|
| Frontend | Flutter (Dart)          |
| Database | Firebase Firestore      |
| State    | Firestore real-time streams |
| Hosting  | Firebase (no custom backend) |

---

## 📱 App Overview

Kyte helps teams and organizations make sense of their structure. Instead of hunting through spreadsheets or static org charts, you get a live, interactive tree that reflects your organization exactly as it is — right now.

Built as a demo-scale tool, it's ideal for small teams, internal tooling prototypes, or as a portfolio project showcasing Flutter + Firebase integration.

No login required. Just open and explore.

---

## 🏗️ Architecture

```
┌─────────────────────────────────┐
│         Flutter Mobile App      │
│  (UI + Tree Logic + Search)     │
└────────────┬────────────────────┘
             │  Read / Write
             ▼
┌─────────────────────────────────┐
│       Firebase Firestore        │
│   (members collection, NoSQL)   │
└─────────────────────────────────┘
```

- The Flutter app communicates **directly** with Firestore — no intermediate server
- Firestore **real-time listeners** push updates to the UI the moment data changes
- Tree structure is **computed client-side** from the flat `members` collection

---

## 📊 Data Model

All employee data lives in a single Firestore collection: `members`

```json
{
  "id": "string",          // Auto-generated Firestore document ID
  "name": "string",        // Employee full name (required)
  "role": "string",        // e.g. "SDE II", "Engineering Manager"
  "department": "string",  // e.g. "Engineering", "Product"
  "team": "string",        // e.g. "Platform", "Growth"
  "managerId": "string | null"  // null = root node (no manager)
}
```

The hierarchy is derived from `managerId` references — members with `managerId: null` become root nodes of the tree.

---

## 🌳 Core Functionality

**Member Management**
- Add a new member with name (required), role, department, team, and optional profile photo
- Edit any field, including reassigning a manager
- Delete a member — their entire subtree is removed automatically

**Relationship Mapping**
- Each member reports to exactly one manager
- A manager can have any number of direct reports
- Circular relationships are prevented by design

**Tree Visualization**
- The org chart renders as a dynamic tree, root-first
- Nodes can be expanded or collapsed interactively
- Tapping a node opens the member's profile
- Selected nodes are visually highlighted
- Tree updates in real time as data changes

**Search**
- Search employees by name
- Matching node is highlighted and auto-scrolled into focus

**Real-Time Updates**
- All additions, edits, and deletions propagate instantly across the UI via Firestore listeners

---

## 🖥️ Screens

**Main Screen — Tree View**
The home screen renders the full organizational hierarchy as an interactive tree. Includes a search bar at the top for quick lookup. Nodes expand/collapse on tap.

**Profile Screen**
Displays a member's full details — name, role, department, team, and their manager. Provides quick access to edit or delete the record.

**Add / Edit Member Screen**
A form to create a new employee or update an existing one. Fields include name, role, department, team, and manager selection from a dropdown list of existing members.

---

## ⚙️ Setup & Installation

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or later)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- A Firebase project with Firestore enabled

### 1. Clone the repository

```bash
git clone https://github.com/your-username/Kyte.git
cd Kyte
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Connect your Firebase project
flutterfire configure
```

This generates `firebase_options.dart` automatically.

### 4. Enable Firestore

In the [Firebase Console](https://console.firebase.google.com/):
- Go to **Firestore Database** → Create database
- Start in **test mode** (for demo usage)

### 5. Run the app

```bash
flutter run
```

---

## 📌 Constraints

- **Single manager only** — Each employee can have at most one direct manager
- **No authentication** — The app is designed for demo/internal use; there are no login flows or role-based access controls
- **Demo scale** — Not optimized for large organizations (hundreds+ of members); intended for small teams and prototyping
- **Client-side tree rendering** — Tree computation happens in the app; very deep hierarchies may impact performance

---

## 🎯 Future Improvements

- **Authentication & roles** — Add Firebase Auth to support admin vs. read-only access
- **Profile photos** — Integrate Firebase Storage for real avatar uploads
- **Export to PDF/PNG** — Let users download a snapshot of the org chart
- **Department/team filters** — Filter the tree view by department or team for large orgs
- **Undo delete** — Add a short grace period or confirmation flow before subtree deletion is finalized

---

## 🤝 Contribution

Contributions are welcome! If you'd like to improve the app:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes and open a pull request

For major changes, please open an issue first to discuss your proposal.

---

<div align="center">
  Built with Flutter & Firebase &nbsp;|&nbsp; Open to contributions
</div>
