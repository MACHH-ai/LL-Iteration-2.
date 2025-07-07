import { useState, useEffect, useCallback } from 'react';
import { supabase } from '@/lib/supabase';
import { useAuth } from '@/contexts/AuthContext';
import { ProblemEntry } from '@/types/learning';

export function useProblemHistory() {
  const { user, isAuthenticated } = useAuth();
  const [problems, setProblems] = useState<ProblemEntry[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchProblems = useCallback(async () => {
    // Reset error state
    setError(null);

    try {
      setIsLoading(true);
      // Check if user is authenticated
      if (!isAuthenticated || !user) {
        console.log('User not authenticated, returning empty problems list');
        setProblems([]);
        return;
      }

      // Handle guest users with mock data
      if (user.isGuest) {
        console.log('Guest user detected, returning mock data');
        setProblems([]); // Empty for guests until they submit problems
        return;
      }

      // Validate user ID format (should be a valid UUID)
      if (!user.id || typeof user.id !== 'string') {
        throw new Error('Invalid user ID format');
      }

      console.log('Fetching problems for authenticated user:', user.id);

      // Query the database for the authenticated user's problems
      const { data, error: fetchError } = await supabase
        .from('problem_submissions')
        .select('*')
        .eq('user_id', user.id)
        .eq('status', 'completed')
        .order('created_at', { ascending: false });

      if (fetchError) {
        console.error('Database query error:', fetchError);
        throw new Error(`Database query failed: ${fetchError.message}`);
      }

      console.log('Successfully fetched problems:', data?.length || 0, 'records');

      if (data && data.length > 0) {
        // Transform database records to ProblemEntry format
        const formattedProblems: ProblemEntry[] = data.map(problem => {
          // Safely extract processing time and convert to minutes
          const processingTimeMs = problem.processing_time_ms || 0;
          const timeSpentMinutes = Math.max(1, Math.floor(processingTimeMs / 60000)) || 5;

          // Safely extract tags
          const tags = Array.isArray(problem.tags) ? problem.tags : [];

          return {
            id: problem.id,
            title: problem.title || 'Untitled Problem',
            description: problem.explanation || problem.solution || 'No description available',
            type: problem.input_type as 'text' | 'image' | 'voice',
            content: problem.text_content || problem.image_url || problem.voice_url || '',
            solution: problem.solution || 'No solution available',
            topic: problem.topic || problem.subject || 'General',
            difficulty: (problem.difficulty as 'easy' | 'medium' | 'hard') || 'medium',
            solvedAt: problem.created_at,
            timeSpent: timeSpentMinutes,
            tags: tags,
            imageUrl: problem.image_url || undefined,
            voiceUrl: problem.voice_url || undefined,
          };
        });

        setProblems(formattedProblems);
      } else {
        console.log('No completed problems found for user');
        setProblems([]);
      }

    } catch (err) {
      console.error('Error in fetchProblems:', err);
      
      // Determine appropriate error message
      let errorMessage = 'Failed to fetch problem history';
      
      if (err instanceof Error) {
        // Handle specific error types
        if (err.message.includes('invalid input syntax for type uuid')) {
          errorMessage = 'Authentication error: Invalid user session. Please sign in again.';
        } else if (err.message.includes('Database query failed')) {
          errorMessage = 'Unable to connect to the database. Please check your internet connection.';
        } else if (err.message.includes('Invalid user ID')) {
          errorMessage = 'Authentication error: Invalid user session. Please sign in again.';
        } else {
          errorMessage = `Error: ${err.message}`;
        }
      }
      
      setError(errorMessage);
      setProblems([]); // Clear problems on error
    } finally {
      setIsLoading(false);
    }
  }, [user, isAuthenticated]);

  // Effect to fetch problems when user authentication state changes
  useEffect(() => {
    fetchProblems();
  }, [fetchProblems]);

  // Manual refetch function for pull-to-refresh or retry scenarios
  const refetch = useCallback(async () => {
    await fetchProblems();
  }, [fetchProblems]);

  return {
    problems,
    isLoading,
    error,
    refetch,
  };
}