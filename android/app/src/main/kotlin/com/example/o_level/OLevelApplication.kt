package com.oef.OLevel.papers

import android.app.Application
import android.util.Log
import androidx.work.Configuration
import java.io.File

/**
 * Custom Application class that handles WorkManager database corruption.
 *
 * This fixes the crash:
 *   SQLiteDiskIOException - disk I/O error (code 4874 SQLITE_IOERR_SHMSIZE)
 *
 * The crash occurs when WorkManager's internal SQLite database gets corrupted,
 * particularly on Oppo/Realme devices. By implementing Configuration.Provider,
 * we gain control over WorkManager initialization and can clean up corrupted
 * database files before WorkManager tries to use them.
 */
class OLevelApplication : Application(), Configuration.Provider {

    private val TAG = "OLevelApplication"

    override fun onCreate() {
        super.onCreate()
        cleanUpCorruptedWorkManagerDb()
    }

    /**
     * Provide custom WorkManager configuration.
     * This prevents the default auto-initialization and lets us control the process.
     */
    override fun getWorkManagerConfiguration(): Configuration =
        Configuration.Builder()
            .setMinimumLoggingLevel(Log.INFO)
            .build()

    /**
     * Cleans up corrupted WorkManager database files.
     *
     * When the WorkManager database (androidx.work.workdb) becomes corrupted,
     * the -shm (shared memory) and -wal (write-ahead log) files can be in a
     * bad state. Deleting these auxiliary files forces SQLite to rebuild them
     * from the main database file on next access.
     *
     * If the main database is also corrupted, we delete everything so
     * WorkManager recreates a fresh database.
     */
    private fun cleanUpCorruptedWorkManagerDb() {
        try {
            val dbDir = getDatabasePath("a]").parentFile ?: return
            val workDbFile = File(dbDir, "androidx.work.workdb")
            val shmFile = File(dbDir, "androidx.work.workdb-shm")
            val walFile = File(dbDir, "androidx.work.workdb-wal")
            val journalFile = File(dbDir, "androidx.work.workdb-journal")

            // If the -shm or -wal files exist, they may be corrupted
            // Delete them to let SQLite rebuild from scratch
            var cleaned = false

            if (shmFile.exists()) {
                shmFile.delete()
                cleaned = true
                Log.d(TAG, "Deleted corrupted WorkManager shm file")
            }

            if (walFile.exists()) {
                walFile.delete()
                cleaned = true
                Log.d(TAG, "Deleted corrupted WorkManager wal file")
            }

            if (journalFile.exists()) {
                journalFile.delete()
                cleaned = true
                Log.d(TAG, "Deleted corrupted WorkManager journal file")
            }

            // If the main db file is very small or zero bytes, it's likely corrupted too
            if (workDbFile.exists() && workDbFile.length() < 100) {
                workDbFile.delete()
                Log.d(TAG, "Deleted corrupted WorkManager database (too small)")
                cleaned = true
            }

            if (cleaned) {
                Log.i(TAG, "WorkManager database cleanup completed")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error cleaning WorkManager database: ${e.message}")
        }
    }
}
