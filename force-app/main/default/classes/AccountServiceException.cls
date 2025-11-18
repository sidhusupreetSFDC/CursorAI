/**
 * Custom exception class for AccountService domain-specific errors
 * @author Salesforce Developer
 * @date 2024
 */
public class AccountServiceException extends Exception {
    
    /**
     * Constructor with message
     * @param message Error message
     */
    public AccountServiceException(String message) {
        this(message, null);
    }
    
    /**
     * Constructor with message and cause
     * @param message Error message
     * @param cause Underlying exception
     */
    public AccountServiceException(String message, Exception cause) {
        super(message);
        if (cause != null) {
            this.setCause(cause);
        }
    }
}

