import { useEffect, useState } from 'react';
import { View, Text, FlatList, ActivityIndicator } from 'react-native';
import { supabase } from '../lib/supabase';

type Event = { id: string; title: string; starts_at: string; city: string | null };

export default function EventsScreen(){
  const [data,setData] = useState<Event[]|null>(null);
  const [loading,setLoading] = useState(true);
  useEffect(() => { (async () => {
    const { data, error } = await supabase
      .from('event').select('id,title,starts_at,city').order('starts_at', { ascending: true });
    if (!error) setData(data as Event[]);
    setLoading(false);
  })(); }, []);
  if (loading) return <ActivityIndicator />;
  return <FlatList data={data ?? []} keyExtractor={i=>i.id}
    renderItem={({item}) => (
      <View style={{padding:16,borderBottomWidth:1,borderColor:'#eee'}}>
        <Text style={{fontWeight:'700'}}>{item.title}</Text>
        <Text>{item.city ?? ''}</Text>
        <Text>{new Date(item.starts_at).toLocaleString()}</Text>
      </View>
    )} />;
}

