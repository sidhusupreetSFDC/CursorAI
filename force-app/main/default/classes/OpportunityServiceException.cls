/**
 * Custom exception class for OpportunityService domain-specific errors
 * @author Salesforce Developer
 * @date 2024
 */
public class OpportunityServiceException extends Exception {
    
    /**
     * Constructor with message
     * @param message Error message
     */
    public OpportunityServiceException(String message) {
        this(message, null);
    }
    
    /**
     * Constructor with message and cause
     * @param message Error message
     * @param cause Underlying exception
     */
    public OpportunityServiceException(String message, Exception cause) {
        super(message);
        if (cause != null) {
            this.setCause(cause);
        }
    }
}

