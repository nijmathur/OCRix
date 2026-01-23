# OCRix Requirements & Roadmap

## Overview

Privacy-focused mobile app for scanning, storing, and AI-powered searching of documents - completely offline. No data ever leaves the device without explicit user consent.

### Core Value Proposition
- **100% Offline**: All processing happens on-device
- **Secure by Design**: AES-256 encryption, biometric protection
- **AI-Powered Search**: Natural language queries via on-device LLM
- **Cross-Device Portability**: Encrypted export/import

---

## Functional Requirements

### 1. Document Capture & OCR
- Camera capture and gallery import
- Multi-page document support
- On-device OCR (Google ML Kit)
- Auto edge detection (nice-to-have)
- Image preprocessing (contrast, brightness)
- Store both encrypted image and extracted text

### 2. Metadata & Organization
- Auto-record: scan date, device, OCR confidence, detected language
- User-defined: document type, tags, notes, location
- Document types: receipt, contract, invoice, manual, business card, ID, passport, license, certificate, other
- Entity extraction: vendor, amount, date, category

### 3. Storage & Encryption
- AES-256 encryption at rest for all images
- Unique IV per encryption operation
- PBKDF2 key derivation (100,000 iterations)
- Secure key storage via flutter_secure_storage
- Never store plaintext images on disk

### 4. Search
- Full-text search (SQLite FTS5)
- Vector similarity search (semantic)
- AI-powered natural language queries
- Filter by type, date, tags
- Query routing (structured vs semantic vs complex)

### 5. AI Search (Hybrid RAG)
- Character n-gram embeddings (384 dimensions)
- Cosine similarity matching
- Gemma 2B LLM for complex queries
- Entity extraction (vendor, amount, date)
- Aggregation queries ("total spent on food")

### 6. Export/Import
- Database export with password encryption
- Export to Google Drive (appDataFolder)
- Import with decryption and validation
- Format: [Salt][IV][Encrypted Data]

### 7. Security
- Biometric authentication (fingerprint, face)
- Google OAuth2 authentication
- Session management with re-auth on resume
- Tamper-proof audit logging with checksums

---

## Non-Functional Requirements

### Performance (100k Document Scale)
- Query response: <50ms simple, <200ms complex
- Vector search: <500ms for 100k documents
- OCR: <2s per page
- UI: 60 FPS scrolling
- Memory: <300MB normal operation

### Reliability
- Database transactions (no corruption)
- Sync consistency (no duplicates)
- Graceful error handling

### Privacy
- No analytics or tracking
- All data encrypted at rest
- No cloud processing

---

## Development Roadmap

### Phase 1: MVP Core (Weeks 1-4)
| Feature | Status |
|---------|--------|
| SQLite database with schema | DONE |
| Document capture UI (camera + gallery) | DONE |
| Basic encryption for images | DONE |
| Document list view | DONE |
| Document viewer | DONE |
| Basic navigation/routing | DONE |

**Phase 1 Status: COMPLETE**

---

### Phase 2: OCR Integration (Weeks 5-6)
| Feature | Status |
|---------|--------|
| OCR library (Google ML Kit) | DONE |
| Background OCR processing | DONE |
| Store extracted text | DONE |
| Display text in viewer | DONE |
| Progress indicators | DONE |

**Phase 2 Status: COMPLETE**

---

### Phase 3: Search Foundation (Weeks 7-8)
| Feature | Status |
|---------|--------|
| Full-text search (FTS5) | DONE |
| Search UI | DONE |
| Search results display | DONE |
| Filter by type, date | DONE |

**Phase 3 Status: COMPLETE**

---

### Phase 4: AI-Powered Search (Weeks 9-12)
| Feature | Status |
|---------|--------|
| Vector embedding generation | DONE |
| Background vectorization | DONE |
| Vector similarity search | DONE |
| LLM integration (Gemma 2B) | DONE |
| Query routing | DONE |
| Entity extraction | DONE |
| Natural language responses | DONE |
| AI Search screen | DONE |

**Phase 4 Status: COMPLETE**

---

### Phase 5: Export/Import (Weeks 13-14)
| Feature | Status |
|---------|--------|
| Database export | DONE |
| Password-based encryption | DONE |
| Google Drive integration | DONE |
| Database import | DONE |
| Decryption and validation | DONE |

**Phase 5 Status: COMPLETE**

---

### Phase 6: Security & Authentication (Weeks 15-16)
| Feature | Status |
|---------|--------|
| Biometric authentication | DONE |
| PIN/Pattern authentication | NOT STARTED |
| Session timeout | PARTIAL |
| Lock screen | PARTIAL |
| Secure storage for auth | DONE |

**Phase 6 Status: ~70% COMPLETE**

---

### Phase 7: Polish & Optimization (Weeks 17-18)
| Feature | Status |
|---------|--------|
| UI/UX refinements | IN PROGRESS |
| Performance optimization | PARTIAL |
| Error handling improvements | DONE |
| Loading states/animations | DONE |
| Logging system | DONE |
| User onboarding | NOT STARTED |
| Help/documentation screens | NOT STARTED |
| Comprehensive testing | NOT STARTED |

**Phase 7 Status: ~40% COMPLETE**

---

## Current Status Summary

```
Phase 1 (MVP Core):      [##########] 100%
Phase 2 (OCR):           [##########] 100%
Phase 3 (Search):        [##########] 100%
Phase 4 (AI Search):     [##########] 100%
Phase 5 (Export/Import): [##########] 100%
Phase 6 (Security):      [#######---]  70%
Phase 7 (Polish):        [####------]  40%

OVERALL PROGRESS:        [########--]  87%
```

---

## Remaining Work (Priority Order)

### High Priority
1. **PIN/Pattern authentication** - Local auth fallback when biometric unavailable
2. **Session timeout** - Auto-lock after inactivity period
3. **Lock screen** - Dedicated lock screen UI

### Medium Priority
4. **User onboarding flow** - First-launch tutorial
5. **Help screens** - In-app documentation
6. **Performance optimization** - Large dataset handling

### Low Priority
7. **Comprehensive testing** - Unit, widget, integration tests
8. **OneDrive integration** - Additional cloud provider
9. **Localization** - Multi-language support
10. **App store deployment** - Play Store / App Store

---

## Database Schema

```sql
-- Documents
CREATE TABLE documents (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  image_path TEXT NOT NULL,
  extracted_text TEXT,
  type TEXT NOT NULL,
  scan_date INTEGER NOT NULL,
  tags TEXT,
  metadata TEXT,
  storage_provider TEXT NOT NULL,
  is_encrypted INTEGER DEFAULT 1,
  confidence_score REAL NOT NULL,
  detected_language TEXT NOT NULL,
  device_info TEXT NOT NULL,
  notes TEXT,
  location TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  is_synced INTEGER DEFAULT 0,
  cloud_id TEXT,
  last_synced_at INTEGER,
  -- Entity extraction columns
  vendor TEXT,
  amount REAL,
  transaction_date TEXT,
  category TEXT
);

-- Multi-page support
CREATE TABLE document_pages (
  id TEXT PRIMARY KEY,
  document_id TEXT NOT NULL,
  page_number INTEGER NOT NULL,
  image_path TEXT NOT NULL,
  extracted_text TEXT,
  thumbnail_path TEXT,
  FOREIGN KEY (document_id) REFERENCES documents(id)
);

-- Full-text search
CREATE VIRTUAL TABLE search_index USING fts5(
  doc_id, title, extracted_text, tags, notes
);

-- Vector embeddings
CREATE TABLE document_embeddings (
  id INTEGER PRIMARY KEY,
  document_id TEXT NOT NULL,
  embedding BLOB NOT NULL,
  text_hash TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (document_id) REFERENCES documents(id)
);

-- Audit logging (tamper-proof)
CREATE TABLE audit_entries (
  id TEXT PRIMARY KEY,
  level TEXT NOT NULL,
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  timestamp INTEGER NOT NULL,
  details TEXT,
  checksum TEXT NOT NULL,
  previous_entry_id TEXT,
  previous_checksum TEXT
);
```

---

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter/Dart |
| State Management | Riverpod |
| Database | SQLite + FTS5 |
| OCR | Google ML Kit |
| Encryption | AES-256 + PBKDF2 |
| LLM | Gemma 2B (flutter_gemma) |
| Vector Search | Cosine similarity |
| Cloud Storage | Google Drive API |
| Auth | Google OAuth2 + Biometrics |
