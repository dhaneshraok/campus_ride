/**
 * Manually set emailVerified = true for Firebase Auth users.
 *
 * Usage:
 *   cd functions
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json node verify-users.js
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json node verify-users.js user@rowan.edu
 */
const { initializeApp, applicationDefault } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");

initializeApp({
  credential: applicationDefault(),
});

async function main() {
  const targetEmail = (process.argv[2] || "").trim().toLowerCase();
  let pageToken;
  let updated = 0;
  let scanned = 0;

  do {
    const result = await getAuth().listUsers(1000, pageToken);
    pageToken = result.pageToken;

    for (const user of result.users) {
      scanned += 1;
      const email = (user.email || "").toLowerCase();

      if (targetEmail && email !== targetEmail) continue;
      if (!user.email) continue;

      if (user.emailVerified) {
        console.log(`  ✓ ${user.email} - already verified`);
        continue;
      }

      await getAuth().updateUser(user.uid, { emailVerified: true });
      console.log(`  ✓ ${user.email} - now verified`);
      updated += 1;
    }
  } while (pageToken);

  if (targetEmail && updated === 0) {
    console.log(`No unverified user updated for: ${targetEmail}`);
  }
  console.log(`Done. Scanned ${scanned} users; verified ${updated} user(s).`);
}

main().catch((err) => {
  console.error("Error:", err.message);
  process.exit(1);
});
