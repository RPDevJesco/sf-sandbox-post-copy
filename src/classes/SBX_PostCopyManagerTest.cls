/**
 * The sf-sandbox-post-copy framework is an open source project managed in Github (https://github.com/GSA/sf-sandbox-post-copy)
 *
 * SBX_PostCopyManagerTest
 *
 * Updated for Salesforce API v65 (Winter '25)
 *
 * Key Changes from v31:
 * - Switched from 'with sharing' to 'inherited sharing'
 * - Enhanced test method naming (removed 'test' prefix as it's redundant with @isTest)
 * - Added Assert class usage (introduced in Spring '21)
 * - Improved test data setup and assertions
 * - Added test documentation
 *
 * @author Derek Benner
 * @author Manikanta Ramineni
 * @author Christian Coleman
 * @date 4/12/2016
 * @modified 11/1/2025 - Updated to API v65
 */
@IsTest
public inherited sharing class SBX_PostCopyManagerTest {

    /**
     * Verifies that the SandboxPostCopy interface executes successfully
     * and creates Post_Copy_Log__c records for tracking
     *
     * Test validates:
     * - Manager executes without errors
     * - Post copy logs are created
     * - Framework processes configured workers
     */
    @IsTest
    static void runApexClass_InitiateSandboxRefresh_VerifyPostCopyLogsCreated() {
        // Given - Setup test context
        SBX_PostCopyManager manager = new SBX_PostCopyManager();

        // When - Execute sandbox post copy
        /**
         * Test.testSandboxPostCopyScript simulates sandbox creation/refresh
         * Parameters:
         *   - SandboxPostCopy implementation
         *   - Organization ID (can use any valid 18-char ID for testing)
         *   - Sandbox ID (can use any valid 18-char ID for testing)
         *   - Sandbox name
         */
        Test.startTest();
        Test.testSandboxPostCopyScript(
                manager,
                UserInfo.getOrganizationId(),
                UserInfo.getOrganizationId(),
                'TestSandbox'
        );
        Test.stopTest();

        // Then - Verify results
        List<Post_Copy_Log__c> logList = [
                SELECT Id, Status__c, Apex_Class__c
                FROM Post_Copy_Log__c
                LIMIT 100
        ];

        Assert.isTrue(
                logList.size() > 0,
                'Expected post copy logs to be created after sandbox refresh simulation'
        );
    }
}