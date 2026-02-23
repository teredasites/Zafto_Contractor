"""
Round 7: Wire remaining strings on medium/heavy pages.
Focuses on specific pages with 10+ remaining hardcoded strings.
"""
import json, os, re

TRANS_DIR = os.path.join('src', 'lib', 'translations')
DASHBOARD_DIR = os.path.join('src', 'app', 'dashboard')

with open(os.path.join(TRANS_DIR, 'en.json'), encoding='utf-8') as f:
    en = json.load(f)

# Additional common keys
COMMON_KEYS = {
    "own": "Own",
    "airMovers": "Air Movers",
    "dehu": "Dehu",
    "scrubbers": "Scrubbers",
    "volume": "Volume",
    "floor": "Floor",
    "walls": "Walls",
    "ceiling": "Ceiling",
    "notRecorded": "Not recorded",
    "selectAll": "Select All",
    "clearAll": "Clear All",
    "preview": "Preview",
    "template": "Template",
    "templates": "Templates",
    "frequency": "Frequency",
    "weekly": "Weekly",
    "monthly": "Monthly",
    "quarterly": "Quarterly",
    "annually": "Annually",
    "daily": "Daily",
    "custom": "Custom",
    "percentage": "Percentage",
    "amount": "Amount",
    "count": "Count",
    "average": "Average",
    "minimum": "Minimum",
    "maximum": "Maximum",
    "firstAndLast": "First & Last",
    "sendNow": "Send Now",
    "sendLater": "Send Later",
    "schedule": "Schedule",
    "addNote": "Add Note",
    "addPhoto": "Add Photo",
    "addDocument": "Add Document",
    "addAttachment": "Add Attachment",
    "viewDetails": "View Details",
    "viewAll": "View All",
    "showMore": "Show More",
    "showLess": "Show Less",
    "loadMore": "Load More",
    "noResults": "No Results",
    "noData": "No Data",
    "unknown": "Unknown",
    "none": "None",
    "all": "All",
    "yes": "Yes",
    "no": "No",
    "open": "Open",
    "closed": "Closed",
    "archived": "Archived",
    "inProgress": "In Progress",
    "onHold": "On Hold",
    "cancelled": "Cancelled",
    "rejected": "Rejected",
    "expired": "Expired",
    "renewed": "Renewed",
    "verified": "Verified",
    "unverified": "Unverified",
    "critical": "Critical",
    "warning": "Warning",
    "info": "Info",
    "success": "Success",
    "error": "Error",
    "priority": "Priority",
    "assignee": "Assignee",
    "dueDate": "Due Date",
    "createdDate": "Created Date",
    "lastUpdated": "Last Updated",
    "nextDue": "Next Due",
    "frequency": "Frequency",
    "attachments": "Attachments",
    "comments": "Comments",
    "history": "History",
    "timeline": "Timeline",
    "overview": "Overview",
    "summary": "Summary",
    "analytics": "Analytics",
    "dashboard": "Dashboard",
    "settings": "Settings",
    "profile": "Profile",
    "notifications": "Notifications",
    "preferences": "Preferences",
    "help": "Help",
    "logout": "Logout",
    "previous": "Previous",
    "next": "Next",
    "back": "Back",
    "forward": "Forward",
    "refresh": "Refresh",
    "retry": "Retry",
    "confirm": "Confirm",
    "submit": "Submit",
    "apply": "Apply",
    "reset": "Reset",
    "clear": "Clear",
    "upload": "Upload",
    "download": "Download",
    "import": "Import",
    "export": "Export",
    "print": "Print",
    "copy": "Copy",
    "paste": "Paste",
    "duplicate": "Duplicate",
    "move": "Move",
    "rename": "Rename",
    "archive": "Archive",
    "restore": "Restore",
    "enable": "Enable",
    "disable": "Disable",
    "activate": "Activate",
    "deactivate": "Deactivate",
    "suspend": "Suspend",
    "resume": "Resume",
    "approve": "Approve",
    "reject": "Reject",
    "send": "Send",
    "receive": "Receive",
    "accept": "Accept",
    "decline": "Decline",
    "assign": "Assign",
    "unassign": "Unassign",
    "link": "Link",
    "unlink": "Unlink",
    "merge": "Merge",
    "split": "Split",
    "lock": "Lock",
    "unlock": "Unlock",
    "pin": "Pin",
    "unpin": "Unpin",
    "star": "Star",
    "unstar": "Unstar",
    "flag": "Flag",
    "unflag": "Unflag",
    "follow": "Follow",
    "unfollow": "Unfollow",
    "share": "Share",
    "mute": "Mute",
    "unmute": "Unmute",
    "block": "Block",
    "unblock": "Unblock",
    "report": "Report",
}

# Page-specific keys
PAGE_KEYS = {
    "settings": {
        "configureNotifications": "Configure which notifications you want to receive",
        "configureWorkflowAutomation": "Configure workflow automation for walkthroughs",
        "enableDisableHere": "Enable/disable notification channels here",
        "savedSuccessfully": "Saved successfully",
        "stripeConnected": "Stripe Connected",
        "notConnected": "Not Connected",
        "displayName": "Display Name",
        "aboutYourCompany": "About Your Company",
        "storageUsed": "Storage Used",
        "auditLogEntries": "Audit Log Entries",
        "dataExport": "Data Export",
    },
    "estimates": {
        "mat": "MAT:",
        "lab": "LAB:",
        "equ": "EQU:",
        "title": "Title:",
        "customer": "Customer:",
        "address": "Address:",
        "cityStateZip": "City/State/Zip:",
        "claimNumber": "Claim #:",
        "policyNumber": "Policy #:",
        "carrierLabel": "Carrier:",
        "adjusterLabel": "Adjuster:",
        "deductibleLabel": "Deductible:",
        "claimLabel": "Claim:",
        "policyLabel": "Policy:",
    },
    "marketplace": {
        "locationLabel": "Location:",
        "tradeLabel": "Trade:",
        "serviceLabel": "Service:",
        "urgencyLabel": "Urgency:",
        "budgetLabel": "Budget:",
        "descriptionLabel": "Description:",
        "amountLabel": "Amount:",
        "typeLabel": "Type:",
        "timelineLabel": "Timeline:",
        "warrantyLabel": "Warranty:",
        "submittedLabel": "Submitted:",
    },
    "email": {
        "composeEmail": "Compose Email",
        "inbox": "Inbox",
        "drafts": "Drafts",
        "allMail": "All Mail",
        "noEmailsFound": "No emails found",
        "manageEmailCommunications": "Manage customer email communications",
        "from": "From",
        "snippet": "Snippet",
        "reply": "Reply",
        "replyAll": "Reply All",
        "forward": "Forward",
        "markRead": "Mark Read",
        "markUnread": "Mark Unread",
        "moveToTrash": "Move to Trash",
        "noConversationSelected": "No conversation selected",
        "selectConversation": "Select a conversation to view",
    },
    "scheduling": {
        "criticalPath": "Critical Path",
        "ganttChart": "Gantt Chart",
        "addDependency": "Add Dependency",
        "addMilestone": "Add Milestone",
        "delayDays": "Delay Days",
        "slackDays": "Slack Days",
        "earlyStart": "Early Start",
        "lateFinish": "Late Finish",
        "noTasksScheduled": "No tasks scheduled",
    },
    "books": {
        "accountNumber": "Account #",
        "financialOverview": "Financial Overview",
        "quickAccess": "Quick Access",
        "recentTransactions": "Recent Transactions",
        "monthlyTrend": "Monthly Trend",
        "navigateToSection": "Navigate to any books section",
        "cashBalance": "Cash Balance",
        "outstandingInvoices": "Outstanding Invoices",
        "unpaidBills": "Unpaid Bills",
        "profitThisMonth": "Profit This Month",
    },
    "recon": {
        "scanDate": "Scan Date",
        "sources": "Sources",
        "measurements": "Measurements",
        "scanType": "Scan Type",
        "scanOptions": "Scan Options",
        "addAddress": "Add Address",
    },
    "walkthroughs": {
        "walkthroughDetails": "Walkthrough Details",
        "scopeOfWork": "Scope of Work",
        "measurementData": "Measurement Data",
        "generateBid": "Generate Bid",
        "roomList": "Room List",
        "damageAssessment": "Damage Assessment",
        "noWalkthroughsFound": "No walkthroughs found",
    },
    "invoices": {
        "invoiceNotFound": "Invoice not found",
        "paymentHistory": "Payment History",
        "sendInvoice": "Send Invoice",
        "createInvoice": "Create Invoice",
        "invoiceTotal": "Invoice Total",
        "balanceDue": "Balance Due",
        "amountPaid": "Amount Paid",
        "paymentTerms": "Payment Terms",
    },
    "bids": {
        "bidOverview": "Bid Overview",
        "optimizePrice": "Optimize Price",
        "bidNotFound": "Bid not found",
        "winProbability": "Win Probability",
        "competitorAnalysis": "Competitor Analysis",
        "priceOptimization": "Price Optimization",
    },
    "changeOrders": {
        "changeOrderTracker": "Change Order Tracker",
        "newChangeOrder": "New Change Order",
        "changeOrderAmount": "Change Order Amount",
        "approvalRequired": "Approval Required",
        "originalAmount": "Original Amount",
        "revisedAmount": "Revised Amount",
    },
    "documents": {
        "documentLibrary": "Document Library",
        "allDocuments": "All Documents",
        "sharedWithMe": "Shared with Me",
        "noDocumentsFound": "No documents found",
        "fileType": "File Type",
        "fileSize": "File Size",
        "lastModified": "Last Modified",
    },
    "lienProtection": {
        "lienTracker": "Lien Tracker",
        "noticesSent": "Notices Sent",
        "lienReleases": "Lien Releases",
        "deadlineApproaching": "Deadline Approaching",
        "noLienItems": "No lien items",
    },
    "serviceAgreements": {
        "agreementTracker": "Agreement Tracker",
        "newAgreement": "New Agreement",
        "renewalDate": "Renewal Date",
        "serviceFrequency": "Service Frequency",
        "noAgreementsFound": "No agreements found",
    },
    "propertyManagement": {
        "leaseDetails": "Lease Details",
        "tenantInfo": "Tenant Info",
        "unitDetails": "Unit Details",
        "rentRoll": "Rent Roll",
        "moveInDate": "Move-In Date",
        "moveOutDate": "Move-Out Date",
        "securityDeposit": "Security Deposit",
        "monthlyRent": "Monthly Rent",
        "leaseStart": "Lease Start",
        "leaseEnd": "Lease End",
        "noLeases": "No leases",
        "noTenants": "No tenants",
        "noUnits": "No units",
    },
}

# Add common keys
common = en.setdefault("common", {})
added_common = 0
for k, v in COMMON_KEYS.items():
    if k not in common:
        common[k] = v
        added_common += 1

# Add page-specific keys
for ns, keys in PAGE_KEYS.items():
    if ns not in en:
        en[ns] = {}
    for k, v in keys.items():
        if k not in en[ns]:
            en[ns][k] = v

with open(os.path.join(TRANS_DIR, 'en.json'), 'w', encoding='utf-8') as f:
    json.dump(en, f, ensure_ascii=False, indent=2)
    f.write('\n')

total_page = sum(len(keys) for keys in PAGE_KEYS.values())
print(f"Added {added_common} new common keys, {total_page} page-specific keys")

# Build replacement map (longest first to avoid partial matches)
TEXT_TO_KEY = []
for k, v in COMMON_KEYS.items():
    TEXT_TO_KEY.append((v, f"common.{k}"))
for ns, keys in PAGE_KEYS.items():
    for k, v in keys.items():
        TEXT_TO_KEY.append((v, f"{ns}.{k}"))

TEXT_TO_KEY.sort(key=lambda x: -len(x[0]))

REPLACEMENTS = []
for text, key in TEXT_TO_KEY:
    escaped = re.escape(text)
    pattern = re.compile(f'>({escaped})</([a-zA-Z][a-zA-Z0-9]*)')
    replacement = f">{{t('{key}')}}</\\2"
    REPLACEMENTS.append((pattern, replacement))


def find_all_translation_scopes(content):
    lines = content.split('\n')
    scopes = []
    i = 0
    while i < len(lines):
        stripped = lines[i].strip()
        is_func = (
            stripped.startswith('export default function') or
            stripped.startswith('export function') or
            re.match(r'^function\s+[A-Z]', stripped)
        )
        if is_func:
            paren_count = 0
            found_paren = False
            brace_count = 0
            body_started = False
            func_end = i
            for j in range(i, len(lines)):
                for ch in lines[j]:
                    if not found_paren:
                        if ch == '(':
                            paren_count += 1
                            found_paren = True
                    elif paren_count > 0:
                        if ch == '(':
                            paren_count += 1
                        elif ch == ')':
                            paren_count -= 1
                    else:
                        if ch == '{':
                            brace_count += 1
                            body_started = True
                        elif ch == '}':
                            brace_count -= 1
                            if body_started and brace_count == 0:
                                func_end = j
                                break
                if body_started and brace_count == 0:
                    break
            body = '\n'.join(lines[i:func_end + 1])
            has_hook = bool(re.search(r'const\s+\{.*\}\s*=\s*useTranslation\(\)', body))
            if has_hook:
                uses_tr = 'const { t: tr }' in body
                scopes.append({
                    'start': i,
                    'end': func_end,
                    'uses_tr': uses_tr,
                })
            i = func_end + 1
            continue
        i += 1
    return scopes


def process_file(filepath):
    with open(filepath, encoding='utf-8') as f:
        content = f.read()
    if 'useTranslation' not in content:
        return 0
    scopes = find_all_translation_scopes(content)
    if not scopes:
        return 0
    lines = content.split('\n')
    total_changes = 0
    for scope in sorted(scopes, key=lambda s: -s['start']):
        start = scope['start']
        end = scope['end']
        uses_tr = scope['uses_tr']
        body = '\n'.join(lines[start:end + 1])
        changes = 0
        for pattern, replacement in REPLACEMENTS:
            matches = pattern.findall(body)
            if matches:
                actual_rep = replacement.replace("t('", "tr('") if uses_tr else replacement
                body = pattern.sub(actual_rep, body)
                changes += len(matches)
        if changes > 0:
            new_lines = body.split('\n')
            lines[start:end + 1] = new_lines
            total_changes += changes
    if total_changes > 0:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))
    return total_changes


grand_total = 0
modified = []
for root, dirs, files in os.walk(DASHBOARD_DIR):
    for fname in files:
        if fname != 'page.tsx':
            continue
        filepath = os.path.join(root, fname)
        changes = process_file(filepath)
        if changes > 0:
            rel = os.path.relpath(filepath, DASHBOARD_DIR).replace(os.sep, '/')
            modified.append((rel, changes))
            grand_total += changes

print(f"\nModified {len(modified)} files with {grand_total} total replacements")
for f, c in sorted(modified, key=lambda x: -x[1]):
    print(f"  {c:3d}  {f}")
