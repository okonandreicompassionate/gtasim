create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name varchar(14) not null default 'Player',
  appearance jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.player_saves (
  user_id uuid primary key references auth.users(id) on delete cascade,
  cash bigint not null default 500000000 check (cash >= 0),
  owns_apartment boolean not null default false,
  apartment_unit smallint,
  updated_at timestamptz not null default now()
);

create table if not exists public.owned_vehicles (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  vehicle_type text not null,
  garage_slot smallint not null check (garage_slot between 1 and 8),
  unique (user_id, garage_slot)
);

create table if not exists public.discoveries (
  user_id uuid not null references auth.users(id) on delete cascade,
  landmark_id text not null,
  discovered_at timestamptz not null default now(),
  primary key (user_id, landmark_id)
);

create table if not exists public.game_stats (
  user_id uuid primary key references auth.users(id) on delete cascade,
  jobs_completed integer not null default 0,
  cash_earned bigint not null default 0,
  best_race_seconds integer check (best_race_seconds is null or best_race_seconds >= 0)
);
alter table public.game_stats
  add column if not exists best_race_seconds integer
  check (best_race_seconds is null or best_race_seconds >= 0);

create table if not exists public.chat_messages (
  id bigint generated always as identity primary key,
  sender_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid references auth.users(id) on delete cascade,
  body varchar(140) not null check (length(body) > 0),
  sent_at timestamptz not null default now()
);

create table if not exists public.races (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete cascade,
  route text[] not null,
  status text not null default 'open'
    check (status in ('open', 'started', 'finished', 'cancelled')),
  created_at timestamptz not null default now()
);

create table if not exists public.race_participants (
  race_id uuid not null references public.races(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  finish_seconds integer check (finish_seconds is null or finish_seconds >= 0),
  primary key (race_id, user_id)
);

alter table public.profiles enable row level security;
alter table public.player_saves enable row level security;
alter table public.owned_vehicles enable row level security;
alter table public.discoveries enable row level security;
alter table public.game_stats enable row level security;
alter table public.chat_messages enable row level security;
alter table public.races enable row level security;
alter table public.race_participants enable row level security;

drop policy if exists "Profiles are visible to signed-in players" on public.profiles;
create policy "Profiles are visible to signed-in players"
  on public.profiles for select to authenticated using (true);
drop policy if exists "Players create their own profile" on public.profiles;
create policy "Players create their own profile"
  on public.profiles for insert to authenticated with check (user_id = (select auth.uid()));
drop policy if exists "Players update their own profile" on public.profiles;
create policy "Players update their own profile"
  on public.profiles for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

drop policy if exists "Players manage their own save" on public.player_saves;
create policy "Players manage their own save"
  on public.player_saves for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

drop policy if exists "Players manage their own vehicles" on public.owned_vehicles;
create policy "Players manage their own vehicles"
  on public.owned_vehicles for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

drop policy if exists "Players manage their own discoveries" on public.discoveries;
create policy "Players manage their own discoveries"
  on public.discoveries for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

drop policy if exists "Leaderboard is visible to signed-in players" on public.game_stats;
create policy "Leaderboard is visible to signed-in players"
  on public.game_stats for select to authenticated using (true);
drop policy if exists "Players manage their own stats" on public.game_stats;
create policy "Players manage their own stats"
  on public.game_stats for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

drop policy if exists "Players read their own or addressed chat" on public.chat_messages;
create policy "Players read their own or addressed chat"
  on public.chat_messages for select to authenticated
  using (recipient_id is null or sender_id = (select auth.uid()) or recipient_id = (select auth.uid()));
drop policy if exists "Players send chat as themselves" on public.chat_messages;
create policy "Players send chat as themselves"
  on public.chat_messages for insert to authenticated
  with check (sender_id = (select auth.uid()));

drop policy if exists "Signed-in players read races" on public.races;
create policy "Signed-in players read races"
  on public.races for select to authenticated using (true);
drop policy if exists "Players create races as themselves" on public.races;
create policy "Players create races as themselves"
  on public.races for insert to authenticated
  with check (created_by = (select auth.uid()));

drop policy if exists "Signed-in players read race participants" on public.race_participants;
create policy "Signed-in players read race participants"
  on public.race_participants for select to authenticated using (true);
drop policy if exists "Players join races as themselves" on public.race_participants;
create policy "Players join races as themselves"
  on public.race_participants for insert to authenticated
  with check (user_id = (select auth.uid()));
drop policy if exists "Players update their own race results" on public.race_participants;
create policy "Players update their own race results"
  on public.race_participants for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'chat_messages'
  ) then
    alter publication supabase_realtime add table public.chat_messages;
  end if;
end
$$;

-- ============================================================
-- v8 additions: weapons, kills/deaths, live leaderboard
-- Safe to re-run (idempotent).
-- ============================================================
alter table public.player_saves
  add column if not exists weapons jsonb not null default '{}'::jsonb;

alter table public.game_stats
  add column if not exists kills integer not null default 0 check (kills >= 0),
  add column if not exists deaths integer not null default 0 check (deaths >= 0),
  add column if not exists updated_at timestamptz not null default now();

create index if not exists game_stats_kills_idx on public.game_stats (kills desc);
create index if not exists game_stats_earned_idx on public.game_stats (cash_earned desc);
create index if not exists game_stats_race_idx on public.game_stats (best_race_seconds) where best_race_seconds is not null;
create index if not exists chat_messages_sent_idx on public.chat_messages (sent_at desc);

-- Live leaderboard: stream game_stats changes to clients
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'game_stats'
  ) then
    alter publication supabase_realtime add table public.game_stats;
  end if;
end
$$;
