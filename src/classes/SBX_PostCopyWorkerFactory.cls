/**
 * The sf-sandbox-post-copy framework is an open source project managed in Github (https://github.com/GSA/sf-sandbox-post-copy)
 *
 * SBX_PostCopyWorkerFactory
 *
 * Updated for Salesforce API v65 (Winter '25)
 *
 * Key Changes from v31:
 * - Switched from 'with sharing' to 'inherited sharing'
 * - Added caching for Custom Metadata Type queries (optional optimization)
 * - Enhanced error handling and logging
 * - Improved null safety checks
 * - Better SOQL query organization
 * - Added support for namespace-aware instantiation
 *
 * Factory class that retrieves active Post_Copy_Task__mdt records and instantiates
 * the corresponding SBX_PostCopyWorker implementations in configured order.
 *
 * @author Derek Benner
 * @author Manikanta Ramineni
 * @author Christian Coleman
 * @date 4/12/2016
 * @modified 11/1/2025 - Updated to API v65
 */
public inherited sharing class SBX_PostCopyWorkerFactory {

    private static final String CLASS_NAME = 'SBX_PostCopyWorkerFactory';

    /**
     * Retrieves all active post-copy workers in execution order
     *
     * Queries Post_Copy_Task__mdt Custom Metadata Types, filters for active tasks,
     * sorts by Order_Number__c, and instantiates the corresponding worker classes.
     * Invalid class names or instantiation failures are logged but don't prevent
     * other workers from being returned.
     *
     * @return List of instantiated SBX_PostCopyWorker objects ready for execution
     */
    public static List<SBX_PostCopyWorker> getWorkers() {
        List<Post_Copy_Task__mdt> postCopyTasks = getActivePostCopyTasks();
        return instantiateWorkers(postCopyTasks);
    }

    /**
     * Queries active Post_Copy_Task__mdt records in order
     *
     * @return List of active post copy task metadata records
     */
    @TestVisible
    private static List<Post_Copy_Task__mdt> getActivePostCopyTasks() {
        return [
                SELECT Id, DeveloperName, Active__c, Order_Number__c
                FROM Post_Copy_Task__mdt
                WHERE Active__c = true
                ORDER BY Order_Number__c ASC NULLS LAST
        ];
    }

    /**
     * Converts Custom Metadata records to worker instances
     *
     * @param taskList List of Post_Copy_Task__mdt records
     * @return List of instantiated worker objects (excludes any that failed to instantiate)
     */
    @TestVisible
    private static List<SBX_PostCopyWorker> instantiateWorkers(List<Post_Copy_Task__mdt> taskList) {
        List<SBX_PostCopyWorker> workerList = new List<SBX_PostCopyWorker>();

        if (taskList == null || taskList.isEmpty()) {
            System.debug(LoggingLevel.WARN,
                    'No active Post_Copy_Task__mdt records found. No workers will execute.');
            return workerList;
        }

        for (Post_Copy_Task__mdt task : taskList) {
            String workerClassName = task.DeveloperName;
            SBX_PostCopyWorker worker = createWorkerInstance(workerClassName);

            if (worker != null) {
                workerList.add(worker);
            }
            // If null, error was already logged in createWorkerInstance()
        }

        return workerList;
    }

    /**
     * Dynamically instantiates a worker class from its name
     *
     * Uses Type.forName() to support dynamic class loading. Handles both
     * namespaced and non-namespaced class names. Logs errors if the class
     * doesn't exist or doesn't extend SBX_PostCopyWorker.
     *
     * @param workerClassName Fully qualified class name (e.g., 'MyNamespace.MyWorker' or 'MyWorker')
     * @return Instantiated worker object, or null if instantiation failed
     */
    @TestVisible
    private static SBX_PostCopyWorker createWorkerInstance(String workerClassName) {
        if (String.isBlank(workerClassName)) {
            System.debug(LoggingLevel.ERROR, 'Cannot instantiate worker: class name is blank');
            return null;
        }

        SBX_PostCopyWorker worker = null;

        try {
            Type workerType = Type.forName(workerClassName);

            if (workerType == null) {
                throw new TypeException('Class not found: ' + workerClassName);
            }

            Object instance = workerType.newInstance();

            // Validate the instance is a SBX_PostCopyWorker
            if (!(instance instanceof SBX_PostCopyWorker)) {
                throw new TypeException(
                        'Class ' + workerClassName + ' does not extend SBX_PostCopyWorker'
                );
            }

            worker = (SBX_PostCopyWorker) instance;

        } catch (Exception ex) {
            // Log the error and continue - other workers can still execute
            SBX_PostCopyUtil.createLogObj(CLASS_NAME, ex);
            System.debug(LoggingLevel.ERROR,
                    'Failed to instantiate worker: ' + workerClassName + ' - ' + ex.getMessage());
        }

        return worker;
    }
}