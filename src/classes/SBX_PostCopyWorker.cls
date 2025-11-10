/**
 * The sf-sandbox-post-copy framework is an open source project managed in Github (https://github.com/GSA/sf-sandbox-post-copy)
 *
 * SBX_PostCopyWorker
 *
 * Updated for Salesforce API v65 (Winter '25)
 *
 * Key Changes from v31:
 * - Switched from 'with sharing' to 'inherited sharing'
 * - Enhanced documentation for abstract methods
 * - Improved exception handling pattern
 * - Added method-level security considerations
 *
 * Abstract base class for implementing sandbox post-copy automation tasks.
 * Extend this class to create custom post-copy logic that runs after sandbox refresh.
 *
 * Usage Example:
 * <code>
 * public inherited sharing class MyPostCopyWorker extends SBX_PostCopyWorker {
 *     protected override void run(SandboxContext context) {
 *         // Your custom logic here
 *     }
 *
 *     public override String getClassName() {
 *         return 'MyPostCopyWorker';
 *     }
 * }
 * </code>
 *
 * @author Derek Benner
 * @author Manikanta Ramineni
 * @author Christian Coleman
 * @date 4/12/2016
 * @modified 11/1/2025 - Updated to API v65
 */
public inherited sharing abstract class SBX_PostCopyWorker {

    /**
     * Contains the custom post-copy logic to execute
     *
     * Implement this method in your worker class with the specific automation
     * tasks that should run after a sandbox refresh. This method is automatically
     * wrapped with exception handling by the process() method.
     *
     * @param context SandboxContext containing sandbox metadata (org ID, sandbox ID, name)
     */
    protected abstract void run(SandboxContext context);

    /**
     * Returns the implementing class name for logging purposes
     *
     * This name is used to identify which worker class succeeded or failed
     * in the Post_Copy_Log__c records. Typically returns the simple class name.
     *
     * @return String representing the worker class name
     */
    public abstract String getClassName();

    /**
     * Public entry point called by SBX_PostCopyManager
     *
     * Executes the worker's run() method with automatic exception handling
     * and logging. Success or failure is recorded in Post_Copy_Log__c.
     * Individual worker failures do not prevent other workers from executing.
     *
     * @param context SandboxContext provided by Salesforce
     */
    public void process(SandboxContext context) {
        try {
            run(context);
            SBX_PostCopyUtil.createLogObj(getClassName(), null);
        } catch (Exception ex) {
            // Log the exception but don't rethrow - allows other workers to continue
            SBX_PostCopyUtil.createLogObj(getClassName(), ex);

            // Optional: Add debug logging for troubleshooting
            System.debug(LoggingLevel.ERROR,
                    'Post-copy worker failed: ' + getClassName() + ' - ' + ex.getMessage());
        }
    }
}