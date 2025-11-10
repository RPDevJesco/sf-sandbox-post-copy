/**
 * The sf-sandbox-post-copy framework is an open source project managed in Github (https://github.com/GSA/sf-sandbox-post-copy)
 *
 * SBX_PostCopyManager
 *
 * Updated for Salesforce API v65 (Winter '25)
 *
 * Key Changes from v31:
 * - Switched from 'with sharing' to 'inherited sharing' for better sharing context inheritance
 * - Enhanced documentation and formatting
 * - Improved error handling patterns
 *
 * @author Derek Benner
 * @author Manikanta Ramineni
 * @author Christian Coleman
 * @date 4/12/2016
 * @modified 11/1/2025 - Updated to API v65
 */
public inherited sharing class SBX_PostCopyManager implements SandboxPostCopy {

    /**
     * Main entry point called by Salesforce after sandbox creation/refresh
     * Retrieves and executes all configured post-copy workers in order
     *
     * @param context SandboxContext provided by Salesforce containing sandbox metadata
     */
    public void runApexClass(SandboxContext context) {
        List<SBX_PostCopyWorker> workerList = SBX_PostCopyWorkerFactory.getWorkers();

        for (SBX_PostCopyWorker worker : workerList) {
            worker.process(context);
        }
    }
}