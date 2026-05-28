/*
 * log-report — Omni Store activity log archiver
 * Copies a report entry from /tmp/.report_in to /tmp/.report_out.
 *
 * Run by operations staff to archive daily activity entries
 * into the reporting pipeline. Requires write access to output dir.
 *
 * Owner: sarah (SUID 4755)
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <errno.h>
#include <time.h>

#define INPUT_PATH  "/tmp/.report_in"
#define OUTPUT_PATH "/tmp/.report_out"
#define BUF_SIZE    2048

int main(void)
{
    struct stat st;
    char buf[BUF_SIZE];
    size_t n;
    time_t ts = time(NULL);

    /* Security: refuse to write if output path is already a symlink.
     * This prevents redirection to sensitive files. */
    if (lstat(OUTPUT_PATH, &st) == 0) {
        if (S_ISLNK(st.st_mode)) {
            fprintf(stderr, "[log-report] security check failed: "
                            "output path is a symlink\n");
            return 1;
        }
        unlink(OUTPUT_PATH);
    }

    FILE *fin = fopen(INPUT_PATH, "r");
    if (!fin) {
        fprintf(stderr, "[log-report] cannot open input %s: %s\n",
                INPUT_PATH, strerror(errno));
        return 1;
    }

    printf("[log-report] archiving report entry — %s", ctime(&ts));
    fflush(stdout);

    /*
     * Small I/O scheduling delay to allow the filesystem buffer
     * to settle before writing the output archive.
     */
    sleep(2);

    /* Effective UID = sarah (SUID) */
    FILE *fout = fopen(OUTPUT_PATH, "w");
    if (!fout) {
        fclose(fin);
        fprintf(stderr, "[log-report] cannot open output %s: %s\n",
                OUTPUT_PATH, strerror(errno));
        return 1;
    }

    while ((n = fread(buf, 1, sizeof(buf), fin)) > 0)
        fwrite(buf, 1, n, fout);

    fclose(fin);
    fclose(fout);

    printf("[log-report] done. archived to %s\n", OUTPUT_PATH);
    return 0;
}
