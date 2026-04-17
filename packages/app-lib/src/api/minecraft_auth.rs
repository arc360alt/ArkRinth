//! Authentication flow interface

use chrono::{Duration, Utc};
use reqwest::StatusCode;
use uuid::Uuid;

use crate::State;
use crate::state::{Credentials, MinecraftLoginFlow, MinecraftProfile};
use crate::util::fetch::REQWEST_CLIENT;

#[tracing::instrument]
pub async fn check_reachable() -> crate::Result<()> {
    let resp = REQWEST_CLIENT
        .get("https://sessionserver.mojang.com/session/minecraft/hasJoined")
        .send()
        .await?;
    if resp.status() == StatusCode::NO_CONTENT {
        return Ok(());
    }
    resp.error_for_status()?;
    Ok(())
}

#[tracing::instrument]
pub async fn begin_login() -> crate::Result<MinecraftLoginFlow> {
    let state = State::get().await?;

    crate::state::login_begin(&state.pool).await
}

#[tracing::instrument]
pub async fn finish_login(
    code: &str,
    flow: MinecraftLoginFlow,
) -> crate::Result<Credentials> {
    let state = State::get().await?;

    crate::state::login_finish(code, flow, &state.pool).await
}

#[tracing::instrument]
pub async fn get_default_user() -> crate::Result<Option<uuid::Uuid>> {
    let state = State::get().await?;
    let user = Credentials::get_active(&state.pool).await?;
    Ok(user.map(|user| user.offline_profile.id))
}

#[tracing::instrument]
pub async fn set_default_user(user: uuid::Uuid) -> crate::Result<()> {
    let state = State::get().await?;
    let users = Credentials::get_all(&state.pool).await?;
    let (_, mut user) = users.remove(&user).ok_or_else(|| {
        crate::ErrorKind::OtherError(format!(
            "Tried to get nonexistent user with ID {user}"
        ))
        .as_error()
    })?;

    user.active = true;
    user.upsert(&state.pool).await?;

    Ok(())
}

/// Remove a user account from the database
#[tracing::instrument]
pub async fn remove_user(uuid: uuid::Uuid) -> crate::Result<()> {
    let state = State::get().await?;

    let users = Credentials::get_all(&state.pool).await?;

    // Remove the user from the database
    Credentials::remove(uuid, &state.pool).await?;

    // If there are any users left, set the first one as active
    let mut remaining = users.into_iter().filter(|(id, _)| *id != uuid);
    if let Some((_, mut user)) = remaining.next() {
        user.active = true;
        user.upsert(&state.pool).await?;
    }

    Ok(())
}

/// Get a copy of the list of all user credentials
#[tracing::instrument]
pub async fn users() -> crate::Result<Vec<Credentials>> {
    let state = State::get().await?;
    let users = Credentials::get_all(&state.pool).await?;
    Ok(users.into_iter().map(|x| x.1).collect())
}

/// Create an offline/local account that doesn't require a Microsoft login.
/// The account uses a random UUID and the given username, and will never
/// attempt to refresh tokens, allowing play on offline-mode servers.
#[tracing::instrument]
pub async fn create_offline_user(username: String) -> crate::Result<Credentials> {
    let state = State::get().await?;

    let credentials = Credentials {
        offline_profile: MinecraftProfile {
            id: Uuid::new_v4(),
            name: username,
            ..MinecraftProfile::default()
        },
        access_token: "OFFLINE_ACCESS_TOKEN".to_string(),
        refresh_token: String::new(),
        // Set expiry far in the future so the refresh logic never fires
        expires: Utc::now() + Duration::days(365 * 100),
        active: true,
    };

    credentials.upsert(&state.pool).await?;

    Ok(credentials)
}
