import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
  Alert,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Link, router } from 'expo-router';
import { Mail, ArrowLeft, Send } from 'lucide-react-native';
import { useAuth } from '@/contexts/AuthContext';
import { useTheme } from '@/contexts/ThemeContext';
import LoadingSpinner from '@/components/LoadingSpinner';

export default function ForgotPasswordScreen() {
  const { requestPasswordReset, isLoading, error, clearError } = useAuth();
  const { colors } = useTheme();
  const [email, setEmail] = useState('');
  const [emailSent, setEmailSent] = useState(false);
  const [emailError, setEmailError] = useState('');

  const validateEmail = (email: string) => {
    if (!email) {
      setEmailError('Email is required');
      return false;
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      setEmailError('Please enter a valid email address');
      return false;
    }
    setEmailError('');
    return true;
  };

  const handleSubmit = async () => {
    clearError();
    
    if (!validateEmail(email)) {
      return;
    }

    try {
      await requestPasswordReset(email);
      setEmailSent(true);
    } catch (err) {
      // Error is handled by context
    }
  };

  const handleBackToLogin = () => {
    router.back();
  };

  if (emailSent) {
    return (
      <KeyboardAvoidingView 
        style={styles.container} 
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      >
        <LinearGradient colors={[colors.primary, colors.primaryDark]} style={styles.gradient}>
          <View style={styles.content}>
            <View style={styles.successContainer}>
              <View style={styles.iconContainer}>
                <LinearGradient
                  colors={['rgba(255,255,255,0.2)', 'rgba(255,255,255,0.1)']}
                  style={styles.iconGradient}
                >
                  <Mail size={40} color="#FFFFFF" />
                </LinearGradient>
              </View>
              
              <Text style={styles.successTitle}>Check Your Email</Text>
              <Text style={styles.successMessage}>
                We've sent password reset instructions to {email}
              </Text>
              
              <View style={[styles.instructionsContainer, { backgroundColor: 'rgba(255,255,255,0.1)' }]}>
                <Text style={styles.instructionsTitle}>What's next?</Text>
                <Text style={styles.instructionItem}>1. Check your email inbox</Text>
                <Text style={styles.instructionItem}>2. Click the reset link in the email</Text>
                <Text style={styles.instructionItem}>3. Create a new password</Text>
                <Text style={styles.instructionItem}>4. Sign in with your new password</Text>
              </View>

              <TouchableOpacity
                style={styles.backButton}
                onPress={handleBackToLogin}
              >
                <LinearGradient
                  colors={['#FFFFFF', '#F0F0F0']}
                  style={styles.backGradient}
                >
                  <ArrowLeft size={20} color={colors.primary} />
                  <Text style={[styles.backButtonText, { color: colors.primary }]}>Back to Sign In</Text>
                </LinearGradient>
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.resendButton}
                onPress={() => setEmailSent(false)}
              >
                <Text style={styles.resendButtonText}>Didn't receive the email? Try again</Text>
              </TouchableOpacity>
            </View>
          </View>
        </LinearGradient>
      </KeyboardAvoidingView>
    );
  }

  return (
    <KeyboardAvoidingView 
      style={styles.container} 
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <LinearGradient colors={[colors.primary, colors.primaryDark]} style={styles.gradient}>
        <View style={styles.content}>
          {/* Header */}
          <View style={styles.header}>
            <TouchableOpacity style={styles.backIcon} onPress={handleBackToLogin}>
              <ArrowLeft size={24} color="#FFFFFF" />
            </TouchableOpacity>
            
            <View style={styles.logoContainer}>
              <LinearGradient
                colors={['rgba(255,255,255,0.2)', 'rgba(255,255,255,0.1)']}
                style={styles.logoGradient}
              >
                <Mail size={40} color="#FFFFFF" />
              </LinearGradient>
            </View>
            
            <Text style={styles.title}>Reset Password</Text>
            <Text style={styles.subtitle}>
              Enter your email address and we'll send you instructions to reset your password
            </Text>
          </View>

          {/* Form */}
          <View style={[styles.formContainer, { backgroundColor: colors.surface }]}>
            {error && (
              <View style={[styles.errorContainer, { backgroundColor: colors.error + '20', borderColor: colors.error }]}>
                <Text style={[styles.errorText, { color: colors.error }]}>{error}</Text>
              </View>
            )}

            <View style={styles.inputContainer}>
              <View style={[styles.inputWrapper, { backgroundColor: colors.surfaceSecondary, borderColor: colors.border }]}>
                <Mail size={20} color={colors.primary} style={styles.inputIcon} />
                <TextInput
                  style={[styles.input, emailError && styles.inputError, { color: colors.text }]}
                  placeholder="Enter your email address"
                  placeholderTextColor={colors.textTertiary}
                  value={email}
                  onChangeText={(text) => {
                    setEmail(text);
                    if (emailError) validateEmail(text);
                  }}
                  keyboardType="email-address"
                  autoCapitalize="none"
                  autoCorrect={false}
                  autoFocus
                />
              </View>
              {emailError && (
                <Text style={[styles.fieldErrorText, { color: colors.error }]}>{emailError}</Text>
              )}
            </View>

            <TouchableOpacity
              style={[styles.submitButton, isLoading && styles.buttonDisabled]}
              onPress={handleSubmit}
              disabled={isLoading}
            >
              <LinearGradient
                colors={isLoading ? [colors.textSecondary, colors.textTertiary] : [colors.primary, colors.primaryDark]}
                style={styles.submitGradient}
              >
                {isLoading ? (
                  <LoadingSpinner size={20} color="#FFFFFF" />
                ) : (
                  <>
                    <Send size={20} color="#FFFFFF" />
                    <Text style={styles.submitButtonText}>Send Reset Instructions</Text>
                  </>
                )}
              </LinearGradient>
            </TouchableOpacity>

            <View style={styles.helpContainer}>
              <Text style={[styles.helpText, { color: colors.textSecondary }]}>Remember your password? </Text>
              <Link href="/auth/login" asChild>
                <TouchableOpacity>
                  <Text style={[styles.helpLink, { color: colors.primary }]}>Sign In</Text>
                </TouchableOpacity>
              </Link>
            </View>
          </View>
        </View>
      </LinearGradient>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  gradient: {
    flex: 1,
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    padding: 20,
  },
  header: {
    alignItems: 'center',
    marginBottom: 40,
    position: 'relative',
  },
  backIcon: {
    position: 'absolute',
    top: 0,
    left: 0,
    padding: 8,
  },
  logoContainer: {
    marginBottom: 20,
  },
  logoGradient: {
    width: 80,
    height: 80,
    borderRadius: 40,
    justifyContent: 'center',
    alignItems: 'center',
  },
  title: {
    fontSize: 32,
    fontWeight: '700',
    color: '#FFFFFF',
    marginBottom: 16,
  },
  subtitle: {
    fontSize: 16,
    color: '#E0E0E0',
    textAlign: 'center',
    lineHeight: 24,
  },
  formContainer: {
    borderRadius: 20,
    padding: 24,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.3,
    shadowRadius: 20,
    elevation: 10,
  },
  errorContainer: {
    borderRadius: 8,
    padding: 12,
    marginBottom: 20,
    borderLeftWidth: 4,
  },
  errorText: {
    fontSize: 14,
    fontWeight: '500',
  },
  inputContainer: {
    marginBottom: 24,
  },
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 12,
    borderWidth: 1,
    paddingHorizontal: 16,
  },
  inputIcon: {
    marginRight: 12,
  },
  input: {
    flex: 1,
    paddingVertical: 16,
    fontSize: 16,
  },
  inputError: {
    borderColor: '#EF4444',
  },
  fieldErrorText: {
    fontSize: 12,
    marginTop: 4,
    marginLeft: 4,
  },
  submitButton: {
    borderRadius: 12,
    overflow: 'hidden',
    marginBottom: 20,
  },
  buttonDisabled: {
    opacity: 0.7,
  },
  submitGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 16,
    gap: 8,
  },
  submitButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  helpContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
  },
  helpText: {
    fontSize: 14,
  },
  helpLink: {
    fontSize: 14,
    fontWeight: '600',
  },
  successContainer: {
    alignItems: 'center',
  },
  iconContainer: {
    marginBottom: 24,
  },
  iconGradient: {
    width: 100,
    height: 100,
    borderRadius: 50,
    justifyContent: 'center',
    alignItems: 'center',
  },
  successTitle: {
    fontSize: 28,
    fontWeight: '700',
    color: '#FFFFFF',
    marginBottom: 16,
  },
  successMessage: {
    fontSize: 16,
    color: '#E0E0E0',
    textAlign: 'center',
    marginBottom: 32,
    lineHeight: 24,
  },
  instructionsContainer: {
    borderRadius: 12,
    padding: 20,
    marginBottom: 32,
    width: '100%',
  },
  instructionsTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 12,
  },
  instructionItem: {
    fontSize: 14,
    color: '#E0E0E0',
    marginBottom: 8,
    lineHeight: 20,
  },
  backButton: {
    borderRadius: 12,
    overflow: 'hidden',
    marginBottom: 16,
    width: '100%',
  },
  backGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 16,
    gap: 8,
  },
  backButtonText: {
    fontSize: 16,
    fontWeight: '600',
  },
  resendButton: {
    paddingVertical: 12,
  },
  resendButtonText: {
    fontSize: 14,
    color: '#E0E0E0',
    textAlign: 'center',
    textDecorationLine: 'underline',
  },
});