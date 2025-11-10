/**
 * The sf-sandbox-post-copy framework is an open source project managed in Github (https://github.com/GSA/sf-sandbox-post-copy)
 *
 * SBX_PostCopyUtil
 *
 * Updated for Salesforce API v65 (Winter '25)
 *
 * Key Changes from v31:
 * - Switched from 'with sharing' to 'inherited sharing'
 * - Enhanced error message handling with truncation for field limits
 * - Improved constant naming and organization
 * - Better exception handling and logging
 * - Added @TestVisible annotation for better test isolation
 *
 * @author Derek Benner
 * @author Manikanta Ramineni
 * @author Christian Coleman
 * @date 4/12/2016
 * @modified 11/1/2025 - Updated to API v65
 */
public inherited sharing class SBX_PostCopyUtil {

    // Status picklist values for Post_Copy_Log__c
    private static final String STATUS_SUCCESS = 'Success';
    private static final String STATUS_FAILURE = 'Error';

    // Delimiter for concatenating error details
    private static final String ERROR_DELIMITER = '|||';

    // Maximum length for error message field (adjust based on your field configuration)
    private static final Integer MAX_ERROR_LENGTH = 32768; // Long Text Area default max

    /**
     * Creates a Post_Copy_Log__c record to track execution results
     *
     * @param className Name of the class being logged
     * @param ex Exception if an error occurred, null for success
     */
    public static void createLogObj(String className, Exception ex) {
        Post_Copy_Log__c logRecord = new Post_Copy_Log__c();
        logRecord.Apex_Class__c = className;

        if (ex != null) {
            logRecord.Status__c = STATUS_FAILURE;
            logRecord.Error_Message__c = formatErrorMessage(ex);
        } else {
            logRecord.Status__c = STATUS_SUCCESS;
        }

        try {
            insert logRecord;
        } catch (DmlException dmlEx) {
            // Log to debug if log creation fails to prevent cascading failures
            System.debug(LoggingLevel.ERROR,
                    'Failed to create Post_Copy_Log__c: ' + dmlEx.getMessage());
        }
    }

    /**
     * Formats exception details into a structured error message
     * Includes line number, message, and stack trace
     * Truncates if necessary to fit field limits
     *
     * @param ex The exception to format
     * @return Formatted error message string
     */
    @TestVisible
    private static String formatErrorMessage(Exception ex) {
        String errorMessage = String.join(
                new List<String>{
                        'Line: ' + ex.getLineNumber(),
                        'Message: ' + ex.getMessage(),
                        'Stack Trace: ' + ex.getStackTraceString()
                },
                ERROR_DELIMITER
        );

        // Truncate if exceeds maximum length
        if (errorMessage.length() > MAX_ERROR_LENGTH) {
            errorMessage = errorMessage.substring(0, MAX_ERROR_LENGTH - 20) +
                    '... [TRUNCATED]';
        }

        return errorMessage;
    }

    /**
     * Custom exception class for testing framework behavior
     * Used in unit tests to simulate controlled exception scenarios
     */
    public class ForcedException extends Exception {
        // Intentionally empty - used only for test simulation
    }
}