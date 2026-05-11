"use client";

import { useEffect, useMemo, useState } from "react";

const API_BASE = "https://pokeapi.co/api/v2/pokemon";
const STARTERS = ["pikachu", "bulbasaur", "charmander", "squirtle", "eevee"];

function formatName(value) {
  return value
    .split("-")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

function normalizeQuery(value) {
  return value.trim().toLowerCase().replace(/\s+/g, "-");
}

function getArtwork(pokemon) {
  return (
    pokemon?.sprites?.other?.["official-artwork"]?.front_default ||
    pokemon?.sprites?.other?.home?.front_default ||
    pokemon?.sprites?.front_default ||
    ""
  );
}

async function fetchPokemon(value) {
  const nextQuery = normalizeQuery(value);

  if (!nextQuery) {
    throw new Error("Enter a Pokemon name or ID.");
  }

  const response = await fetch(`${API_BASE}/${encodeURIComponent(nextQuery)}`);

  if (!response.ok) {
    throw new Error("Pokemon not found.");
  }

  return response.json();
}

export default function Home() {
  const [isOpen, setIsOpen] = useState(false);
  const [query, setQuery] = useState("pikachu");
  const [pokemon, setPokemon] = useState(null);
  const [status, setStatus] = useState("loading");
  const [error, setError] = useState("");

  const typeNames = useMemo(
    () => pokemon?.types?.map((entry) => entry.type.name) || [],
    [pokemon]
  );

  function applyPokemon(data) {
    setPokemon(data);
    setQuery(data.name);
    setStatus("success");
  }

  async function loadPokemon(value) {
    setStatus("loading");
    setError("");

    try {
      const data = await fetchPokemon(value);
      applyPokemon(data);
    } catch (requestError) {
      setPokemon(null);
      setError(requestError.message || "Unable to load Pokemon.");
      setStatus("error");
    }
  }

  useEffect(() => {
    let isMounted = true;

    async function loadInitialPokemon() {
      try {
        const data = await fetchPokemon("pikachu");

        if (isMounted) {
          applyPokemon(data);
        }
      } catch (requestError) {
        if (isMounted) {
          setPokemon(null);
          setError(requestError.message || "Unable to load Pokemon.");
          setStatus("error");
        }
      }
    }

    loadInitialPokemon();

    return () => {
      isMounted = false;
    };
  }, []);

  function handleSubmit(event) {
    event.preventDefault();
    loadPokemon(query);
  }

  return (
    <main className="pokedex-stage">
      <section className={`pokedex-shell ${isOpen ? "is-open" : "is-closed"}`} aria-label="Pokedex">
        <div className="closed-cover" aria-hidden={isOpen}>
          <div className="cover-top">
            <span className="lens lens-large" />
            <span className="lens lens-red" />
            <span className="lens lens-yellow" />
            <span className="lens lens-green" />
          </div>
          <div className="cover-line" />
          <div className="cover-badge">POKEDEX</div>
          <button className="open-button" type="button" onClick={() => setIsOpen(true)}>
            OPEN
          </button>
        </div>

        <div className="book-spread" aria-hidden={!isOpen}>
          <div className="left-page">
            <div className="top-controls">
              <span className="lens lens-large" />
              <span className="lens lens-red" />
              <span className="lens lens-yellow" />
              <span className="lens lens-green" />
            </div>

            <div className="screen-frame">
              <div className="screen">
                {status === "loading" ? (
                  <div className="screen-state">SCANNING</div>
                ) : pokemon ? (
                  <img
                    className="pokemon-art"
                    src={getArtwork(pokemon)}
                    alt={formatName(pokemon.name)}
                  />
                ) : (
                  <div className="screen-state">NO SIGNAL</div>
                )}
              </div>
            </div>

            <form className="search-panel" onSubmit={handleSubmit}>
              <label htmlFor="pokemon-search">SEARCH</label>
              <div className="search-row">
                <input
                  id="pokemon-search"
                  value={query}
                  onChange={(event) => setQuery(event.target.value)}
                  placeholder="name or id"
                  autoComplete="off"
                />
                <button type="submit">GO</button>
              </div>
            </form>

            <div className="quick-list" aria-label="Quick Pokemon">
              {STARTERS.map((name) => (
                <button key={name} type="button" onClick={() => loadPokemon(name)}>
                  {formatName(name)}
                </button>
              ))}
            </div>
          </div>

          <div className="hinge" aria-hidden="true" />

          <div className="right-page">
            <div className="right-header">
              <div>
                <p className="index-number">{pokemon ? `NO. ${String(pokemon.id).padStart(3, "0")}` : "NO. ---"}</p>
                <h1>{pokemon ? formatName(pokemon.name) : "Unknown"}</h1>
              </div>
              <button className="close-button" type="button" onClick={() => setIsOpen(false)}>
                CLOSE
              </button>
            </div>

            {error ? <p className="error-message">{error}</p> : null}

            <div className="type-row">
              {typeNames.length > 0
                ? typeNames.map((type) => (
                    <span className={`type-chip type-${type}`} key={type}>
                      {type.toUpperCase()}
                    </span>
                  ))
                : <span className="type-chip">UNKNOWN</span>}
            </div>

            <div className="bio-grid">
              <div>
                <span>HEIGHT</span>
                <strong>{pokemon ? `${(pokemon.height / 10).toFixed(1)} m` : "--"}</strong>
              </div>
              <div>
                <span>WEIGHT</span>
                <strong>{pokemon ? `${(pokemon.weight / 10).toFixed(1)} kg` : "--"}</strong>
              </div>
              <div>
                <span>BASE EXP</span>
                <strong>{pokemon?.base_experience || "--"}</strong>
              </div>
            </div>

            <section className="data-section">
              <h2>STATS</h2>
              <div className="stats-list">
                {(pokemon?.stats || []).map((entry) => (
                  <div className="stat-row" key={entry.stat.name}>
                    <span>{formatName(entry.stat.name)}</span>
                    <div className="stat-track">
                      <div style={{ width: `${Math.min(entry.base_stat, 160) / 1.6}%` }} />
                    </div>
                    <strong>{entry.base_stat}</strong>
                  </div>
                ))}
              </div>
            </section>

            <section className="data-section">
              <h2>ABILITIES</h2>
              <div className="ability-list">
                {(pokemon?.abilities || []).map((entry) => (
                  <span key={entry.ability.name}>{formatName(entry.ability.name)}</span>
                ))}
              </div>
            </section>
          </div>
        </div>
      </section>
    </main>
  );
}
