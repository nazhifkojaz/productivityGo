import { useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import axios from 'axios';
import { toast } from 'sonner';

export default function TimezoneSync() {
    const { session } = useAuth();

    useEffect(() => {
        const syncTimezone = async () => {
            if (!session?.access_token) return;

            try {
                // 1. Get current profile timezone
                const { data: profile } = await axios.get('/api/users/profile', {
                    headers: { Authorization: `Bearer ${session.access_token}` }
                });

                const currentProfileTimezone = profile.timezone || 'UTC';
                const browserTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone;

                // 2. Only auto-update if profile is UTC (default) and browser is NOT UTC
                // This ensures we catch new users (signup) but don't overwrite manual settings
                if (currentProfileTimezone === 'UTC' && browserTimezone !== 'UTC') {
                    console.log(`Auto-syncing timezone from ${currentProfileTimezone} to ${browserTimezone}`);

                    await axios.put('/api/users/profile',
                        { timezone: browserTimezone },
                        { headers: { Authorization: `Bearer ${session.access_token}` } }
                    );

                    toast.success(`Timezone set to ${browserTimezone}`);
                }
            } catch (error) {
                console.error("Failed to sync timezone", error);
            }
        };

        syncTimezone();
    }, [session]);

    return null; // Render nothing
}
