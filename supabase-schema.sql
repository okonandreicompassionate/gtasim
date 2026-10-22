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

create table if not exists public.friendships (
  requester_id uuid not null references auth.users(id) on delete cascade,
  addressee_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted')),
  created_at timestamptz not null default now(),
  primary key (requester_id, addressee_id),
  check (requester_id <> addressee_id)
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
alter table public.friendships enable row level security;
alter table public.races enable row level security;
alter table public.race_participants enable row level security;

-- Game progression is account-only: guests use no database save path.
revoke all on public.profiles, public.player_saves, public.owned_vehicles,
  public.discoveries, public.game_stats from anon;
revoke all on public.friendships from anon;
grant select, insert, update on public.profiles to authenticated;
grant select, insert, update, delete on public.player_saves,
  public.owned_vehicles, public.discoveries, public.game_stats to authenticated;
grant select, insert, update, delete on public.friendships to authenticated;

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

drop policy if exists "Players read their friendships" on public.friendships;
create policy "Players read their friendships"
  on public.friendships for select to authenticated
  using (requester_id = (select auth.uid()) or addressee_id = (select auth.uid()));
drop policy if exists "Players send friend requests" on public.friendships;
create policy "Players send friend requests"
  on public.friendships for insert to authenticated
  with check (requester_id = (select auth.uid()) and status = 'pending');
drop policy if exists "Players accept friend requests" on public.friendships;
create policy "Players accept friend requests"
  on public.friendships for update to authenticated
  using (addressee_id = (select auth.uid()) and status = 'pending')
  with check (addressee_id = (select auth.uid()) and status = 'accepted');
drop policy if exists "Players remove friendships" on public.friendships;
create policy "Players remove friendships"
  on public.friendships for delete to authenticated
  using (requester_id = (select auth.uid()) or addressee_id = (select auth.uid()));

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

-- Daily login rewards are claimed atomically so a refresh or a second device
-- cannot claim the same Lagos calendar day twice.
alter table public.player_saves
  add column if not exists weapons jsonb not null default '{}'::jsonb;

create table if not exists public.daily_login_claims (
  user_id uuid primary key references auth.users(id) on delete cascade,
  last_claim_date date not null,
  streak_day integer not null check (streak_day > 0),
  updated_at timestamptz not null default now()
);

alter table public.daily_login_claims enable row level security;
revoke all on public.daily_login_claims from anon, authenticated;
grant select on public.daily_login_claims to authenticated;

drop policy if exists "Players view their own login claim" on public.daily_login_claims;
create policy "Players view their own login claim"
  on public.daily_login_claims for select to authenticated
  using (user_id = (select auth.uid()));

create or replace function public.claim_daily_login_reward(p_claim_date date)
returns table(claimed boolean, reward bigint, streak_day integer, claim_date date)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_today date := (now() at time zone 'Africa/Lagos')::date;
  v_last date;
  v_streak integer;
  v_reward bigint;
  v_saved_day text;
  v_saved_claim text;
  v_saved_streak text;
begin
  if v_user is null then
    raise exception 'Authentication required';
  end if;
  if p_claim_date is distinct from v_today then
    raise exception 'Daily login claim date is invalid';
  end if;

  insert into public.player_saves(user_id)
    values (v_user)
    on conflict (user_id) do nothing;
  perform 1 from public.player_saves as ps
    where ps.user_id = v_user
    for update;

  select dlc.last_claim_date, dlc.streak_day
    into v_last, v_streak
    from public.daily_login_claims as dlc
    where dlc.user_id = v_user;

  if found and v_last = v_today then
    return query select false, 0::bigint, v_streak, v_today;
    return;
  end if;

  if not found then
    select ps.weapons->'dy'->>'d', ps.weapons->'dy'->>'cl', ps.weapons->'dy'->>'st'
      into v_saved_day, v_saved_claim, v_saved_streak
      from public.player_saves as ps
      where ps.user_id = v_user;
    v_streak := case when v_saved_streak ~ '^[0-9]{1,7}$' then v_saved_streak::integer else 1 end;
    if v_saved_day = v_today::text and v_saved_claim in ('true', '1') then
      v_streak := greatest(v_streak, 1);
      insert into public.daily_login_claims(user_id, last_claim_date, streak_day)
        values (v_user, v_today, v_streak);
      return query select false, 0::bigint, v_streak, v_today;
      return;
    end if;
    v_streak := case when v_saved_day = (v_today - 1)::text and v_saved_claim in ('true', '1')
      then greatest(v_streak, 1) + 1 else 1 end;
  else
    v_streak := case when v_last = v_today - 1 then v_streak + 1 else 1 end;
  end if;

  v_reward := case ((v_streak - 1) % 7) + 1
    when 1 then 20000000
    when 2 then 30000000
    when 3 then 40000000
    when 4 then 60000000
    when 5 then 80000000
    when 6 then 100000000
    else 250000000
  end;

  insert into public.daily_login_claims(user_id, last_claim_date, streak_day, updated_at)
    values (v_user, v_today, v_streak, now())
    on conflict (user_id) do update
      set last_claim_date = excluded.last_claim_date,
          streak_day = excluded.streak_day,
          updated_at = excluded.updated_at;
  update public.player_saves as ps
    set cash = ps.cash + v_reward, updated_at = now()
    where ps.user_id = v_user;

  return query select true, v_reward, v_streak, v_today;
end
$$;

revoke all on function public.claim_daily_login_reward(date) from public, anon;
grant execute on function public.claim_daily_login_reward(date) to authenticated;

-- ============================================================
-- v8 additions: weapons, kills/deaths, live leaderboard
-- Safe to re-run (idempotent).
-- ============================================================
alter table public.game_stats
  add column if not exists kills integer not null default 0 check (kills >= 0),
  add column if not exists deaths integer not null default 0 check (deaths >= 0),
  add column if not exists updated_at timestamptz not null default now();

create index if not exists game_stats_kills_idx on public.game_stats (kills desc);
create index if not exists game_stats_earned_idx on public.game_stats (cash_earned desc);
create index if not exists game_stats_race_idx on public.game_stats (best_race_seconds) where best_race_seconds is not null;
create index if not exists chat_messages_sent_idx on public.chat_messages (sent_at desc);
create index if not exists friendships_addressee_idx on public.friendships (addressee_id, status);

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

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'friendships'
  ) then
    alter publication supabase_realtime add table public.friendships;
  end if;
end
$$;
