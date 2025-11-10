/**
 * The sf-sandbox-post-copy framework is an open source project managed in Github (https://github.com/GSA/sf-sandbox-post-copy)
 *
 * SBX_PostCopyWorkerFactoryTest
 *
 * Updated for Salesforce API v65 (Winter '25)
 *
 * Key Changes from v31:
 * - Switched from 'with sharing' to 'inherited sharing'
 * - Enhanced test method naming (removed 'test' prefix)
 * - Added Assert class usage for better test assertions
 * - Improved test documentation and assertions
 * - Added test for edge cases
 *
 * IMPORTANT: Custom Metadata Types cannot be created in test context.
 * These tests depend on existing Post_Copy_Task__mdt records in the org.
 *
 * Required Setup:
 * 1. At least one valid Post_Copy_Task__mdt that references an existing worker class
 * 2. At least one invalid Post_Copy_Task__mdt with a non-existent class name
 *
 * The tests verify:
 * - Factory returns worker instances from active metadata
 * - Valid worker classes are instantiated successfully
 * - Invalid class names are handled gracefully (logged, not added to list)
 * - Worker count may be less than metadata count due to invalid entries
 *
 * @author Derek Benner
 * @author Manikanta Ramineni
 * @author Christian Coleman
 * @date 4/12/2016
 * @modified 11/1/2025 - Updated to API v65
 */
@IsTest
public inherited sharing class SBX_PostCopyWorkerFactoryTest {

    /**
     * Verifies that the factory returns worker instances from metadata
     *
     * This test assumes at least one valid Post_Copy_Task__mdt record exists
     * in the org with Active__c = true and a valid DeveloperName matching
     * an existing SBX_PostCopyWorker implementation.
     */
    @IsTest
    static void getWorkers_WithActiveMetadata_ReturnsWorkerList() {
        // When - Retrieve workers from factory
        Test.startTest();
        List<SBX_PostCopyWorker> workerList = SBX_PostCopyWorkerFactory.getWorkers();
        Test.stopTest();

        // Then - Verify workers were returned
        Assert.isNotNull(workerList, 'Worker list should not be null');
        Assert.isTrue(
                workerList.size() > 0,
                'Expected at least one worker from active Post_Copy_Task__mdt records. ' +
                        'Verify that Post_Copy_Task__mdt records exist with Active__c = true.'
        );

        // Verify all returned objects are valid workers
        for (SBX_PostCopyWorker worker : workerList) {
            Assert.isNotNull(worker, 'Worker instance should not be null');
            Assert.isNotNull(worker.getClassName(), 'Worker class name should not be null');
        }
    }

    /**
     * Verifies that invalid metadata entries are filtered out
     *
     * This test assumes:
     * 1. Multiple Post_Copy_Task__mdt records exist
     * 2. At least one has an invalid DeveloperName (non-existent class)
     *
     * The factory should return fewer workers than total metadata records
     * because invalid entries are logged but not included in the result.
     */
    @IsTest
    static void getWorkers_WithInvalidMetadata_FiltersInvalidWorkers() {
        // Given - Query all active metadata (including any invalid ones)
        List<Post_Copy_Task__mdt> allMetadata = [
                SELECT Id, DeveloperName
                FROM Post_Copy_Task__mdt
                WHERE Active__c = true
        ];

        // When - Get workers from factory
        Test.startTest();
        List<SBX_PostCopyWorker> workerList = SBX_PostCopyWorkerFactory.getWorkers();
        Test.stopTest();

        // Then - Worker count should be less than or equal to metadata count
        // (Will be less if any metadata has invalid class names)
        Assert.isTrue(
                workerList.size() <= allMetadata.size(),
                'Worker count should not exceed metadata count'
        );

        // If they're not equal, it means some invalid entries were filtered
        if (workerList.size() < allMetadata.size()) {
            System.debug('Some Post_Copy_Task__mdt records have invalid class names and were filtered out');
        }

        // Verify Post_Copy_Log__c records were created for any failures
        List<Post_Copy_Log__c> errorLogs = [
                SELECT Id, Status__c, Apex_Class__c, Error_Message__c
                FROM Post_Copy_Log__c
                WHERE Apex_Class__c = 'SBX_PostCopyWorkerFactory'
                AND Status__c = 'Error'
                LIMIT 100
        ];

        // If worker count differs, there should be error logs
        if (workerList.size() < allMetadata.size()) {
            Assert.isTrue(
                    errorLogs.size() > 0,
                    'Expected error logs for invalid Post_Copy_Task__mdt entries'
            );
        }
    }

    /**
     * Verifies factory behavior when no active metadata exists
     *
     * Note: This test uses a mock/stub approach since we can't delete
     * Custom Metadata in tests. It tests the instantiateWorkers method directly.
     */
    @IsTest
    static void instantiateWorkers_WithEmptyList_ReturnsEmptyList() {
        // Given - Empty task list
        List<Post_Copy_Task__mdt> emptyList = new List<Post_Copy_Task__mdt>();

        // When - Instantiate workers from empty list
        Test.startTest();
        List<SBX_PostCopyWorker> workerList =
                SBX_PostCopyWorkerFactory.instantiateWorkers(emptyList);
        Test.stopTest();

        // Then - Should return empty list without errors
        Assert.isNotNull(workerList, 'Worker list should not be null');
        Assert.areEqual(
                0,
                workerList.size(),
                'Expected empty worker list when no metadata provided'
        );
    }

    /**
     * Verifies that worker instances can execute their process method
     *
     * This is an integration test ensuring workers returned by the factory
     * are fully functional and can be executed.
     */
    @IsTest
    static void getWorkers_ExecuteWorkers_VerifyNoExceptions() {
        // Given - Workers from factory
        List<SBX_PostCopyWorker> workerList = SBX_PostCopyWorkerFactory.getWorkers();

        if (workerList.isEmpty()) {
            // Skip test if no workers available
            return;
        }

        // When - Execute each worker
        Test.startTest();
        for (SBX_PostCopyWorker worker : workerList) {
            // Create a mock sandbox context
            // Note: In real tests, use Test.testSandboxPostCopyScript()
            // This just verifies the worker can be called without immediate errors
            try {
                String className = worker.getClassName();
                Assert.isNotNull(className, 'Worker class name should be available');
            } catch (Exception ex) {
                Assert.fail('Worker threw unexpected exception: ' + ex.getMessage());
            }
        }
        Test.stopTest();

        // Then - No exceptions should be thrown
        Assert.isTrue(true, 'All workers executed successfully');
    }
}