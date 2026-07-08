# WhatsApp Templates (Marathi) — GATEE Portal

Submit these in the reseller panel (rcs.mmtpro.in account) for Meta approval.
All templates: **Language = Marathi (mr)**, **Category = UTILITY**, **Parameter format = Positional**.

Footer for ALL templates (same as approved `hm_approval_alert`):

```
प्रादेशिक उपसंचालक लातूर, इतर मागास बहुजन कल्याण विभाग
```

Common parameter convention (matches `hm_approval_alert`):
- `{{1}}` = contact name (HM / School Coordinator)
- `{{2}}` = UDISE number
- `{{3}}` = school name
- `{{4}}` onwards = scenario-specific values

---

## 1. palak_melava_schedule — पालक मेळावा आयोजन सूचना

**Scenario:** Division/District informs the school that a Palak Melava is scheduled; school must conduct it and upload photos + details afterwards.

**Body:**
```
नमस्कार {{1}},

शाळा UDISE {{2}} — {{3}}

आपल्या शाळेत दिनांक {{4}} रोजी पालक मेळावा (क्र. {{5}}) आयोजित करावयाचा आहे. कृपया सर्व पालकांना वेळेत कळवून मेळाव्याचे आयोजन करावे आणि मेळाव्यानंतर फोटो व उपस्थितीची माहिती GATEE Portal वर त्वरित अपलोड करावी.
```

**Sample values (for approval):** `{{1}}` श्री. पाटील सर | `{{2}}` 27290100101 | `{{3}}` जि.प. प्राथमिक शाळा, लातूर | `{{4}}` १५/०७/२०२६ | `{{5}}` २

---

## 2. palak_melava_pending — पालक मेळावा माहिती प्रलंबित

**Scenario:** Melava was due/conducted but photos & details are not uploaded on the portal yet.

**Body:**
```
नमस्कार {{1}},

शाळा UDISE {{2}} — {{3}}

आपल्या शाळेच्या पालक मेळावा क्र. {{4}} ची माहिती व फोटो अद्याप GATEE Portal वर अपलोड झालेले नाहीत. कृपया पोर्टलवर लॉग इन करून प्रलंबित माहिती तात्काळ अपलोड करावी, अन्यथा मेळावा अपूर्ण गणला जाईल.
```

**Sample values:** `{{1}}` श्री. पाटील सर | `{{2}}` 27290100101 | `{{3}}` जि.प. प्राथमिक शाळा, लातूर | `{{4}}` २

---

## 3. phase_start_alert — चरण सुरू होण्याची सूचना

**Scenario:** A new phase (चरण 1–4) opens on the portal from a given date; school should begin data entry.

**Body:**
```
नमस्कार {{1}},

शाळा UDISE {{2}} — {{3}}

GATEE Portal वर चरण {{4}} ची माहिती भरण्याची प्रक्रिया दिनांक {{5}} पासून सुरू होत आहे. कृपया शाळा समन्वयक यांच्यामार्फत सर्व विद्यार्थ्यांची माहिती वेळेत भरण्याची कार्यवाही सुरू करावी.
```

**Sample values:** `{{1}}` श्री. पाटील सर | `{{2}}` 27290100101 | `{{3}}` जि.प. प्राथमिक शाळा, लातूर | `{{4}}` ३ | `{{5}}` ०१/०८/२०२६

---

## 4. phase_closing_soon — चरण बंद होण्याची आठवण

**Scenario:** Phase deadline approaching; X days remain to complete data entry.

**Body:**
```
नमस्कार {{1}},

शाळा UDISE {{2}} — {{3}}

GATEE Portal वरील चरण {{4}} ची माहिती भरण्याची अंतिम मुदत दिनांक {{5}} आहे. आता फक्त {{6}} दिवस शिल्लक आहेत. कृपया आपल्या शाळेची प्रलंबित माहिती त्वरित पूर्ण करून मुख्याध्यापकांची मंजुरी घ्यावी.
```

**Sample values:** `{{1}}` श्री. पाटील सर | `{{2}}` 27290100101 | `{{3}}` जि.प. प्राथमिक शाळा, लातूर | `{{4}}` ३ | `{{5}}` ३१/०८/२०२६ | `{{6}}` ५

---

## 5. phase_pending_activity — चरणातील प्रलंबित माहिती

**Scenario:** Some students' data for a phase is still not filled; shows pending student count.

**Body:**
```
नमस्कार {{1}},

शाळा UDISE {{2}} — {{3}}

चरण {{4}} मध्ये आपल्या शाळेतील {{5}} विद्यार्थ्यांची माहिती अद्याप GATEE Portal वर भरलेली नाही. कृपया पोर्टलवर लॉग इन करून प्रलंबित माहिती तात्काळ पूर्ण करावी व पुढील मंजुरीची कार्यवाही करावी.
```

**Sample values:** `{{1}}` श्री. पाटील सर | `{{2}}` 27290100101 | `{{3}}` जि.प. प्राथमिक शाळा, लातूर | `{{4}}` २ | `{{5}}` १८

---

## Submission checklist (reseller panel)

1. Category **UTILITY** (not Marketing — utility gets approved faster and is cheaper).
2. Language **Marathi (mr)** — must match exactly, code `mr`, since sends specify `"code":"mr"`.
3. Paste the body text with `{{1}}`…`{{6}}` placeholders as-is; fill the sample values above where the panel asks for examples (Meta requires samples).
4. Add the common footer text.
5. No buttons needed (can add a "GATEE Portal" URL button later if desired — that changes the send payload).
6. After approval, verify with `getTemplateList` — status must be `APPROVED` before sending.

## Java constants (already added to WhatsAppConfig.java)

| Template | Constant | Params |
|---|---|---|
| palak_melava_schedule | `TPL_MELAVA_SCHEDULE` | name, UDISE, school, date, melava no |
| palak_melava_pending | `TPL_MELAVA_PENDING` | name, UDISE, school, melava no |
| phase_start_alert | `TPL_PHASE_START` | name, UDISE, school, phase, start date |
| phase_closing_soon | `TPL_PHASE_CLOSING` | name, UDISE, school, phase, last date, days left |
| phase_pending_activity | `TPL_PHASE_PENDING` | name, UDISE, school, phase, pending count |

Send example:
```java
WhatsAppService.getInstance().sendTemplateMessage(mobile,
    WhatsAppConfig.TPL_PHASE_CLOSING, WhatsAppConfig.LANG_MR,
    new String[]{ name, udise, schoolName, "3", "31/08/2026", "5" });
```
