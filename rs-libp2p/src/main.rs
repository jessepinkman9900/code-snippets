use futures::StreamExt;
use libp2p::{
  Multiaddr, noise,
  ping::{self, Event},
  swarm::SwarmEvent,
  tcp, yamux,
};
use std::{error::Error, time::Duration};

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
  let _ = tracing_subscriber::fmt()
    .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
    .try_init();

  let mut swarm = libp2p::SwarmBuilder::with_new_identity()
    .with_tokio()
    .with_tcp(
      tcp::Config::default(),
      noise::Config::new,
      yamux::Config::default,
    )?
    .with_behaviour(|_| ping::Behaviour::default())?
    .with_swarm_config(|cfg| cfg.with_idle_connection_timeout(Duration::from_secs(u64::MAX)))
    .build();

  // tell swarm to listen on all interfaces and a random os assigned port
  swarm.listen_on("/ip4/0.0.0.0/tcp/0".parse()?)?;

  if let Some(addr) = std::env::args().nth(1) {
    let remote: Multiaddr = addr.parse()?;
    swarm.dial(remote)?;
    println!("Dialed {addr}");
  }

  loop {
    match swarm.select_next_some().await {
      SwarmEvent::NewListenAddr { address, .. } => println!("Listening on {address}"),
      SwarmEvent::Behaviour(event) => println!("Ping event: {event:?}"),
      _ => {}
    }
  }
}
