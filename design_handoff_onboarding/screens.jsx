// Relay — screen components
// Aesthetic: warm cream paper, ink-on-paper, mono for technical, serif for spoken thoughts.
// All screens are 402×874 (iOS frame default).

const RELAY_T = {
  bg:     '#F2EEE4',
  paper:  '#FAF6EC',
  ink:    '#181613',
  muted:  'rgba(24,22,19,0.58)',
  faint:  'rgba(24,22,19,0.34)',
  hair:   'rgba(24,22,19,0.09)',
  hair2:  'rgba(24,22,19,0.16)',
  amber:  'oklch(0.66 0.14 55)',     // recording
  sage:   'oklch(0.58 0.055 165)',   // connected / ack
  rust:   'oklch(0.55 0.14 28)',     // error
  sans:   '"Söhne", -apple-system, "SF Pro Text", system-ui, sans-serif',
  serif:  '"Newsreader", "Iowan Old Style", Georgia, serif',
  mono:   '"JetBrains Mono", "SF Mono", ui-monospace, monospace',
};

// ─────────────────────────────────────────────────────────────
// shared chrome — Relay's own header (replaces stock iOS nav)
// ─────────────────────────────────────────────────────────────
function RelayHeader({ status = 'connected', detail = '@relay_bot · 412 ms' }) {
  const dot = {
    connected: RELAY_T.sage,
    recording: RELAY_T.amber,
    offline:   RELAY_T.rust,
    speaking:  RELAY_T.amber,
  }[status] || RELAY_T.sage;

  return (
    <div style={{
      paddingTop: 60, padding: '60px 24px 18px',
      display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between',
    }}>
      <div style={{
        fontFamily: RELAY_T.sans, fontWeight: 500, fontSize: 19,
        letterSpacing: -0.2, color: RELAY_T.ink,
        display: 'flex', alignItems: 'center', gap: 8,
      }}>
        <span style={{
          width: 8, height: 8, borderRadius: 9999, background: dot,
          boxShadow: status === 'recording' ? `0 0 0 4px ${RELAY_T.amber}22` : 'none',
        }} />
        relay
      </div>
      <div style={{
        fontFamily: RELAY_T.mono, fontSize: 10.5, letterSpacing: 0.2,
        color: RELAY_T.muted, textTransform: 'lowercase',
      }}>
        {detail}
      </div>
    </div>
  );
}

// route pill (mono, hairline)
function RouteTag({ children, tone = 'ink' }) {
  const col = tone === 'sage' ? RELAY_T.sage : tone === 'rust' ? RELAY_T.rust : RELAY_T.ink;
  return (
    <span style={{
      fontFamily: RELAY_T.mono, fontSize: 10, letterSpacing: 0.4,
      color: col, textTransform: 'lowercase',
      border: `0.5px solid ${RELAY_T.hair2}`, borderRadius: 4,
      padding: '2px 6px 1.5px',
      whiteSpace: 'nowrap',
    }}>
      → {children}
    </span>
  );
}

// row in the captures log
function CaptureRow({ time, text, route, routeTone, pending, failed }) {
  return (
    <div style={{
      padding: '14px 24px',
      borderBottom: `0.5px solid ${RELAY_T.hair}`,
      display: 'flex', gap: 14, alignItems: 'flex-start',
      opacity: pending ? 0.5 : 1,
    }}>
      <div style={{
        fontFamily: RELAY_T.mono, fontSize: 10.5, color: RELAY_T.faint,
        letterSpacing: 0.4, paddingTop: 4, width: 38, flexShrink: 0,
      }}>{time}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontFamily: RELAY_T.serif, fontSize: 16, lineHeight: 1.32,
          color: RELAY_T.ink, letterSpacing: -0.1,
          textWrap: 'pretty',
        }}>
          {text}
        </div>
        <div style={{ marginTop: 6, display: 'flex', gap: 6, alignItems: 'center' }}>
          {pending && (
            <span style={{
              fontFamily: RELAY_T.mono, fontSize: 10, color: RELAY_T.faint,
              letterSpacing: 0.4,
            }}>queued · offline</span>
          )}
          {failed && (
            <span style={{
              fontFamily: RELAY_T.mono, fontSize: 10, color: RELAY_T.rust,
              letterSpacing: 0.4,
            }}>failed · retry?</span>
          )}
          {!pending && !failed && route && <RouteTag tone={routeTone}>{route}</RouteTag>}
        </div>
      </div>
    </div>
  );
}

function DayLabel({ children }) {
  return (
    <div style={{
      padding: '20px 24px 4px',
      fontFamily: RELAY_T.mono, fontSize: 10, letterSpacing: 1.2,
      color: RELAY_T.faint, textTransform: 'uppercase',
    }}>{children}</div>
  );
}

// big bottom action zone — “Hold to speak” + AirPods hint
function HoldToSpeak({ label = 'hold to speak', sub = 'or press AirPods stem' }) {
  return (
    <div style={{
      position: 'absolute', bottom: 34, left: 0, right: 0,
      padding: '0 24px',
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10,
    }}>
      <div style={{
        width: '100%', height: 64, borderRadius: 18,
        background: RELAY_T.ink,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: '0 1px 0 rgba(255,255,255,0.04) inset, 0 12px 24px -10px rgba(0,0,0,0.4)',
      }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 12,
          color: '#F8F4EA',
        }}>
          {/* mic glyph */}
          <svg width="14" height="18" viewBox="0 0 14 18" fill="none">
            <rect x="4.25" y="0.75" width="5.5" height="10" rx="2.75" stroke="currentColor" strokeWidth="1.2"/>
            <path d="M1.5 8.25c0 3.18 2.46 5.75 5.5 5.75s5.5 -2.57 5.5 -5.75M7 14v3M4 17h6" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round"/>
          </svg>
          <div style={{
            fontFamily: RELAY_T.sans, fontSize: 16, fontWeight: 500,
            letterSpacing: -0.1,
          }}>{label}</div>
        </div>
      </div>
      <div style={{
        fontFamily: RELAY_T.mono, fontSize: 10, color: RELAY_T.faint,
        letterSpacing: 0.3,
      }}>{sub}</div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 1. HOME — with captures
// ─────────────────────────────────────────────────────────────
function ScreenHome() {
  return (
    <div data-screen-label="01 Home" style={{
      background: RELAY_T.bg, width: '100%', height: '100%',
      position: 'relative', overflow: 'hidden',
    }}>
      <RelayHeader status="connected" detail="@relay_bot · 412 ms" />

      <div style={{ paddingBottom: 200 }}>
        <DayLabel>today · sat 17 may</DayLabel>
        <CaptureRow
          time="14:32"
          text="Mit Jan über das Pairing reden, vielleicht ein QR-Flow statt Shared Secret."
          route="ideas/relay"
        />
        <CaptureRow
          time="11:08"
          text="Annie Dillard, das Buch aus dem Podcast — kommt mit auf die Leseliste."
          route="reading"
        />
        <CaptureRow
          time="09:47"
          text="Gelbe Tonne morgen früh raus."
          route="tickler"
        />
        <CaptureRow
          time="08:12"
          text="Strom für Espressomaschine, 16-Uhr-Timer ist Quatsch — auf 7:15 ändern."
          route="home"
        />

        <DayLabel>yesterday</DayLabel>
        <CaptureRow
          time="22:04"
          text="Wenn Relay v2 das Approval-Deck bringt, muss Permission-Relay vorher rein."
          route="ideas/relay"
        />
        <CaptureRow
          time="18:31"
          text="Ben fragen ob er Lust hat mitzubauen. Nach Pfingsten."
          route="people"
        />
        <CaptureRow
          time="17:14"
          text="Drei Dinge auf einmal — Email an Maja schreiben, Müsli kaufen, und schauen ob die Tickets schon da sind."
          route="3 items"
          routeTone="sage"
        />
      </div>

      <HoldToSpeak />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 2. LISTENING — pressed, waiting for first words
// ─────────────────────────────────────────────────────────────
function Waveform({ active = true, amp = 1, tint }) {
  // 24 thin vertical bars, deterministic “amplitude” pattern
  const bars = Array.from({ length: 32 }, (_, i) => {
    const seed = Math.sin(i * 1.31) * 0.5 + Math.cos(i * 0.7) * 0.5;
    const h = Math.max(4, (Math.abs(seed) * 30 + 4) * amp);
    return h;
  });
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 4, height: 44,
      justifyContent: 'center',
    }}>
      {bars.map((h, i) => (
        <div key={i} style={{
          width: 3, height: h, borderRadius: 2,
          background: tint || RELAY_T.amber,
          opacity: active ? (0.55 + Math.sin(i * 0.5) * 0.35) : 0.25,
        }} />
      ))}
    </div>
  );
}

function ScreenListening() {
  return (
    <div data-screen-label="02 Listening" style={{
      background: RELAY_T.bg, width: '100%', height: '100%',
      position: 'relative', overflow: 'hidden',
    }}>
      <RelayHeader status="recording" detail="recording · 0:01" />

      {/* centered, restrained */}
      <div style={{
        position: 'absolute', inset: '0 0 0 0',
        display: 'flex', flexDirection: 'column', alignItems: 'center',
        justifyContent: 'center', padding: '0 36px',
        gap: 28,
      }}>
        {/* pulsing dot */}
        <div style={{
          width: 14, height: 14, borderRadius: 9999, background: RELAY_T.amber,
          boxShadow: `0 0 0 8px ${RELAY_T.amber}22, 0 0 0 18px ${RELAY_T.amber}10`,
        }} />
        <div style={{
          fontFamily: RELAY_T.serif, fontSize: 22, color: RELAY_T.faint,
          letterSpacing: -0.2, textAlign: 'center', lineHeight: 1.35,
          fontStyle: 'italic',
        }}>
          listening…
        </div>
        <Waveform active amp={0.3} />
      </div>

      {/* bottom: tap to stop */}
      <div style={{
        position: 'absolute', bottom: 34, left: 24, right: 24,
        display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10,
      }}>
        <div style={{
          width: '100%', height: 64, borderRadius: 18,
          background: 'transparent',
          border: `1px solid ${RELAY_T.hair2}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: RELAY_T.ink,
          fontFamily: RELAY_T.sans, fontSize: 16, fontWeight: 500,
        }}>
          tap to send
        </div>
        <div style={{
          fontFamily: RELAY_T.mono, fontSize: 10, color: RELAY_T.faint,
        }}>or pause 1.5s</div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 3. RECORDING — live transcript filling
// ─────────────────────────────────────────────────────────────
function ScreenRecording() {
  return (
    <div data-screen-label="03 Recording" style={{
      background: RELAY_T.bg, width: '100%', height: '100%',
      position: 'relative', overflow: 'hidden',
    }}>
      <RelayHeader status="recording" detail="recording · 0:08" />

      <div style={{
        padding: '32px 28px 200px',
      }}>
        <div style={{
          fontFamily: RELAY_T.mono, fontSize: 10, letterSpacing: 1.2,
          color: RELAY_T.faint, textTransform: 'uppercase', marginBottom: 14,
        }}>transcript · whisper base</div>

        <div style={{
          fontFamily: RELAY_T.serif, fontSize: 22, lineHeight: 1.4,
          color: RELAY_T.ink, letterSpacing: -0.2,
          textWrap: 'pretty',
        }}>
          Idee für Relay: vielleicht statt einem Shared Secret eher ein
          kurzer QR-Code-Pairing-Flow,{' '}
          <span style={{ color: RELAY_T.faint }}>
            der einmal beim Setup gescannt wird und dann{' '}
          </span>
          <span style={{
            display: 'inline-block', width: 10, height: 22,
            background: RELAY_T.amber, verticalAlign: '-4px',
            marginLeft: 2,
            animation: 'relay-caret 0.9s steps(2,end) infinite',
          }} />
        </div>
      </div>

      {/* bottom: live amplitude + send */}
      <div style={{
        position: 'absolute', bottom: 34, left: 24, right: 24,
        display: 'flex', flexDirection: 'column', gap: 16,
      }}>
        <Waveform active amp={1} />
        <div style={{
          width: '100%', height: 64, borderRadius: 18,
          background: RELAY_T.amber,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: '#FAF6EC',
          fontFamily: RELAY_T.sans, fontSize: 16, fontWeight: 500,
          boxShadow: `0 12px 24px -10px ${RELAY_T.amber}88`,
        }}>
          release to send
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 4. ACK — silent dropbox confirmation
// ─────────────────────────────────────────────────────────────
function ScreenAck() {
  return (
    <div data-screen-label="04 Captured" style={{
      background: RELAY_T.bg, width: '100%', height: '100%',
      position: 'relative', overflow: 'hidden',
    }}>
      <RelayHeader status="connected" detail="@relay_bot · 412 ms" />

      <div style={{
        position: 'absolute', inset: 0,
        display: 'flex', flexDirection: 'column', alignItems: 'center',
        justifyContent: 'center', padding: '0 40px', gap: 22,
      }}>
        {/* checkmark — minimal, hairline */}
        <div style={{
          width: 64, height: 64, borderRadius: 9999,
          border: `1.25px solid ${RELAY_T.sage}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
            <path d="M4 11.5l5 5L18 6" stroke={RELAY_T.sage} strokeWidth="1.5"
              strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>

        <div style={{
          fontFamily: RELAY_T.serif, fontSize: 26, color: RELAY_T.ink,
          letterSpacing: -0.4, fontStyle: 'italic',
        }}>
          captured.
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, alignItems: 'center' }}>
          <div style={{
            fontFamily: RELAY_T.mono, fontSize: 11, color: RELAY_T.muted,
            letterSpacing: 0.4,
          }}>
            c0b3f · routed to <span style={{ color: RELAY_T.ink }}>obsidian/inbox</span>
          </div>
          <div style={{
            fontFamily: RELAY_T.mono, fontSize: 10, color: RELAY_T.faint,
            letterSpacing: 0.4,
          }}>
            0.84 s · silent
          </div>
        </div>
      </div>

      <div style={{
        position: 'absolute', bottom: 60, left: 0, right: 0,
        textAlign: 'center',
        fontFamily: RELAY_T.mono, fontSize: 10, color: RELAY_T.faint,
        letterSpacing: 0.4,
      }}>this screen will fade in 2s · tap to keep</div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 5. SPEAK — Claude needs to talk back (error or clarification)
// ─────────────────────────────────────────────────────────────
function ScreenSpeak() {
  return (
    <div data-screen-label="05 Speaking" style={{
      background: RELAY_T.bg, width: '100%', height: '100%',
      position: 'relative', overflow: 'hidden',
    }}>
      <RelayHeader status="speaking" detail="speaking via airpods" />

      <div style={{
        padding: '40px 28px 0',
      }}>
        <div style={{
          fontFamily: RELAY_T.mono, fontSize: 10, letterSpacing: 1.2,
          color: RELAY_T.faint, textTransform: 'uppercase',
          display: 'flex', alignItems: 'center', gap: 8, marginBottom: 22,
        }}>
          <span style={{
            width: 6, height: 6, borderRadius: 9999, background: RELAY_T.rust,
          }} />
          claude · reply_voice
        </div>

        <div style={{
          fontFamily: RELAY_T.serif, fontSize: 24, lineHeight: 1.4,
          color: RELAY_T.ink, letterSpacing: -0.3,
          textWrap: 'pretty',
        }}>
          Obsidian war nicht erreichbar — der Vault auf deinem Rechner meldet sich nicht.
          Nichts gespeichert. Soll ich's lokal puffern?
        </div>

        <div style={{ marginTop: 24 }}>
          <Waveform active amp={0.7} tint={RELAY_T.rust} />
        </div>

        <div style={{
          marginTop: 28, padding: '14px 16px',
          border: `0.5px solid ${RELAY_T.hair2}`, borderRadius: 12,
          background: RELAY_T.paper,
        }}>
          <div style={{
            fontFamily: RELAY_T.mono, fontSize: 10, color: RELAY_T.faint,
            letterSpacing: 0.4, marginBottom: 6,
          }}>your last capture · c0b40</div>
          <div style={{
            fontFamily: RELAY_T.serif, fontSize: 14, lineHeight: 1.4,
            color: RELAY_T.muted, fontStyle: 'italic',
          }}>
            "Gelbe Tonne morgen früh raus."
          </div>
        </div>
      </div>

      <div style={{
        position: 'absolute', bottom: 34, left: 24, right: 24,
        display: 'flex', gap: 10,
      }}>
        <div style={{
          flex: 1, height: 56, borderRadius: 16,
          border: `1px solid ${RELAY_T.hair2}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: RELAY_T.sans, fontSize: 15, fontWeight: 500,
          color: RELAY_T.ink,
        }}>dismiss</div>
        <div style={{
          flex: 1.4, height: 56, borderRadius: 16,
          background: RELAY_T.ink, color: '#F8F4EA',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: RELAY_T.sans, fontSize: 15, fontWeight: 500,
        }}>hold to reply</div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 6. SETTINGS — server, secret, mic, model
// ─────────────────────────────────────────────────────────────
function SettingRow({ label, value, hint, tone, last }) {
  return (
    <div style={{
      padding: '16px 24px',
      borderBottom: last ? 'none' : `0.5px solid ${RELAY_T.hair}`,
      display: 'flex', alignItems: 'center', gap: 14,
    }}>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontFamily: RELAY_T.sans, fontSize: 15, color: RELAY_T.ink,
          letterSpacing: -0.1,
        }}>{label}</div>
        {hint && (
          <div style={{
            fontFamily: RELAY_T.mono, fontSize: 10, color: RELAY_T.faint,
            letterSpacing: 0.3, marginTop: 4,
          }}>{hint}</div>
        )}
      </div>
      <div style={{
        fontFamily: RELAY_T.mono, fontSize: 11.5,
        color: tone === 'sage' ? RELAY_T.sage : tone === 'rust' ? RELAY_T.rust : RELAY_T.muted,
        letterSpacing: 0.3, textAlign: 'right', maxWidth: '60%',
        overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
      }}>{value}</div>
    </div>
  );
}

function SettingSection({ title, children }) {
  return (
    <div style={{ marginBottom: 24 }}>
      <div style={{
        padding: '0 24px 8px',
        fontFamily: RELAY_T.mono, fontSize: 10, letterSpacing: 1.2,
        color: RELAY_T.faint, textTransform: 'uppercase',
      }}>{title}</div>
      <div style={{
        background: RELAY_T.paper,
        borderTop: `0.5px solid ${RELAY_T.hair2}`,
        borderBottom: `0.5px solid ${RELAY_T.hair2}`,
      }}>{children}</div>
    </div>
  );
}

function ScreenSettings() {
  return (
    <div data-screen-label="06 Settings" style={{
      background: RELAY_T.bg, width: '100%', height: '100%',
      position: 'relative', overflow: 'hidden',
    }}>
      <RelayHeader status="connected" detail="settings" />

      <div style={{ padding: '12px 0 40px' }}>
        <SettingSection title="channel">
          <SettingRow
            label="Bot"
            hint="telegram · BotFather"
            value="@mein_relay_bot"
          />
          <SettingRow
            label="Chat-ID"
            hint="die einzige, die gehört wird"
            value="8 421 9·· ····"
          />
          <SettingRow
            label="Bot-Token"
            hint="im Keychain · re-pair zum Wechseln"
            value="●●●●●●●●·····  show"
          />
          <SettingRow
            label="Plugin"
            hint="auf dem Host geladen"
            value="telegram@…official"
            last
          />
        </SettingSection>

        <SettingSection title="verbindung">
          <SettingRow
            label="Channel"
            value="open"
            tone="sage"
          />
          <SettingRow
            label="Round-trip"
            hint="iPhone → Bot → Claude · letzte 10"
            value="412 ms · ø"
          />
          <SettingRow
            label="Claude Code session"
            hint="systemd · claude --channels …"
            value="up · 4d 11h"
            tone="sage"
            last
          />
        </SettingSection>

        <SettingSection title="voice">
          <SettingRow
            label="Whisper model"
            hint="on-device · 152 MB"
            value="base · multilingual"
          />
          <SettingRow
            label="Voice activity end"
            value="1.5 s"
          />
          <SettingRow
            label="TTS"
            hint="AVSpeech · de-DE"
            value="Markus"
            last
          />
        </SettingSection>

        <SettingSection title="behaviour">
          <SettingRow
            label="Confirm tone on ack"
            value="on"
          />
          <SettingRow
            label="Auto-send on pause"
            value="on"
          />
          <SettingRow
            label="Offline buffer"
            hint="captures kept while disconnected"
            value="unlimited"
            last
          />
        </SettingSection>

        <SettingSection title="commands">
          <SettingRow
            label="Commands"
            hint="send · vergessen — edit aliases"
            value="2  ›"
            last
          />
        </SettingSection>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 7. CONNECTION — diagnostics screen
// ─────────────────────────────────────────────────────────────
function ScreenConnection() {
  return (
    <div data-screen-label="07 Connection" style={{
      background: RELAY_T.bg, width: '100%', height: '100%',
      position: 'relative', overflow: 'hidden',
    }}>
      <RelayHeader status="connected" detail="channel · ok" />

      <div style={{ padding: '12px 24px 40px' }}>
        {/* Big "OK" panel */}
        <div style={{
          marginTop: 8,
          padding: '24px 22px',
          border: `0.5px solid ${RELAY_T.hair2}`, borderRadius: 18,
          background: RELAY_T.paper,
        }}>
          <div style={{
            fontFamily: RELAY_T.mono, fontSize: 10, letterSpacing: 1.2,
            color: RELAY_T.faint, textTransform: 'uppercase',
            display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14,
          }}>
            <span style={{
              width: 6, height: 6, borderRadius: 9999, background: RELAY_T.sage,
            }} />
            channel · ok
          </div>
          <div style={{
            fontFamily: RELAY_T.serif, fontSize: 26, color: RELAY_T.ink,
            letterSpacing: -0.4, lineHeight: 1.2,
          }}>
            iPhone → @mein_relay_bot → <span style={{ color: RELAY_T.faint, fontStyle: 'italic' }}>
              Claude Code, zu Hause.
            </span>
          </div>
        </div>

        {/* metrics grid */}
        <div style={{ marginTop: 24, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 1, background: RELAY_T.hair2, borderRadius: 12, overflow: 'hidden' }}>
          {[
            ['rtt p50',      '412 ms'],
            ['rtt p99',      '780 ms'],
            ['telegram api', 'reachable'],
            ['queue',        '0 pending'],
            ['since',        '4d 11h'],
            ['captures',     '218 ✓ · 0 ✗'],
          ].map(([k, v], i) => (
            <div key={i} style={{
              background: RELAY_T.paper, padding: '14px 16px',
            }}>
              <div style={{
                fontFamily: RELAY_T.mono, fontSize: 10, color: RELAY_T.faint,
                letterSpacing: 0.6, textTransform: 'uppercase', marginBottom: 4,
              }}>{k}</div>
              <div style={{
                fontFamily: RELAY_T.mono, fontSize: 15, color: RELAY_T.ink,
                letterSpacing: -0.2,
              }}>{v}</div>
            </div>
          ))}
        </div>

        {/* Sparkline of recent RTT */}
        <div style={{ marginTop: 24 }}>
          <div style={{
            fontFamily: RELAY_T.mono, fontSize: 10, letterSpacing: 1.2,
            color: RELAY_T.faint, textTransform: 'uppercase', marginBottom: 10,
          }}>round-trip · last hour</div>
          <svg width="100%" height="60" viewBox="0 0 340 60" preserveAspectRatio="none">
            <line x1="0" y1="55" x2="340" y2="55" stroke={RELAY_T.hair2} strokeWidth="0.5"/>
            <polyline
              fill="none"
              stroke={RELAY_T.ink}
              strokeWidth="1.25"
              points={Array.from({ length: 60 }, (_, i) => {
                const x = (i / 59) * 340;
                const v = 28 + Math.sin(i * 0.55) * 8 + Math.cos(i * 0.13) * 4 + (i === 41 ? 18 : 0);
                const y = 58 - v;
                return `${x},${y}`;
              }).join(' ')}
            />
          </svg>
          <div style={{
            fontFamily: RELAY_T.mono, fontSize: 10, color: RELAY_T.faint,
            display: 'flex', justifyContent: 'space-between', marginTop: 4,
          }}>
            <span>−60 min</span><span>now</span>
          </div>
        </div>

        {/* Run mic test */}
        <div style={{
          marginTop: 28,
          height: 56, borderRadius: 16,
          border: `1px solid ${RELAY_T.hair2}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: RELAY_T.sans, fontSize: 15, fontWeight: 500,
          color: RELAY_T.ink,
        }}>run mic test</div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 8. FIRST RUN — paired but no captures yet
// ─────────────────────────────────────────────────────────────
function ScreenFirstRun() {
  return (
    <div data-screen-label="08 First run" style={{
      background: RELAY_T.bg, width: '100%', height: '100%',
      position: 'relative', overflow: 'hidden',
    }}>
      <RelayHeader status="connected" detail="paired · ready" />

      <div style={{
        padding: '50px 28px 0',
      }}>
        <div style={{
          fontFamily: RELAY_T.serif, fontSize: 34, lineHeight: 1.15,
          color: RELAY_T.ink, letterSpacing: -0.6,
          textWrap: 'pretty',
        }}>
          Ein ruhiger Kanal{' '}
          <span style={{ color: RELAY_T.faint, fontStyle: 'italic' }}>
            zu dem, was zu Hause auf dich wartet.
          </span>
        </div>

        <div style={{ marginTop: 36, display: 'flex', flexDirection: 'column', gap: 18 }}>
          {[
            ['1', 'Halt das Telefon ans Ohr oder drück den AirPods-Stem.'],
            ['2', 'Sprich frei. Pausen sind okay. Multi-Item ist okay.'],
            ['3', 'Loslassen. Claude legt es da ab, wo es hingehört.'],
          ].map(([n, t]) => (
            <div key={n} style={{ display: 'flex', gap: 14, alignItems: 'flex-start' }}>
              <div style={{
                width: 22, height: 22, borderRadius: 9999,
                border: `0.75px solid ${RELAY_T.hair2}`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: RELAY_T.mono, fontSize: 11, color: RELAY_T.muted,
                flexShrink: 0,
              }}>{n}</div>
              <div style={{
                fontFamily: RELAY_T.serif, fontSize: 17, lineHeight: 1.45,
                color: RELAY_T.ink, letterSpacing: -0.1,
                paddingTop: 1,
              }}>{t}</div>
            </div>
          ))}
        </div>

        <div style={{
          marginTop: 40,
          padding: '14px 16px',
          border: `0.5px dashed ${RELAY_T.hair2}`, borderRadius: 12,
        }}>
          <div style={{
            fontFamily: RELAY_T.mono, fontSize: 10, color: RELAY_T.faint,
            letterSpacing: 0.4, marginBottom: 4,
          }}>verbunden via</div>
          <div style={{
            fontFamily: RELAY_T.mono, fontSize: 13, color: RELAY_T.ink,
            letterSpacing: 0.2,
          }}>@mein_relay_bot → claude code</div>
          <div style={{
            fontFamily: RELAY_T.mono, fontSize: 10, color: RELAY_T.faint,
            letterSpacing: 0.3, marginTop: 4,
          }}>4 mcps available · obsidian, ticktick, home-assistant, gmail</div>
        </div>
      </div>

      <HoldToSpeak label="try it" sub="say anything · captured silently" />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// ONBOARDING
// ─────────────────────────────────────────────────────────────

function OnboardBottom({ step, total, primary, primaryVariant = 'solid', secondary, primaryAccent }) {
  const solid = primaryVariant === 'solid';
  const bg = primaryAccent || RELAY_T.ink;
  return (
    <div style={{
      position: 'absolute', bottom: 34, left: 24, right: 24,
      display: 'flex', flexDirection: 'column', gap: 14,
    }}>
      {/* step dots */}
      <div style={{
        display: 'flex', justifyContent: 'center', gap: 6, marginBottom: 4,
      }}>
        {Array.from({ length: total }, (_, i) => (
          <div key={i} style={{
            width: i === step - 1 ? 18 : 6, height: 6, borderRadius: 9999,
            background: i < step ? RELAY_T.ink : RELAY_T.hair2,
            transition: 'all 0.3s',
          }} />
        ))}
      </div>
      <div style={{
        width: '100%', height: 60, borderRadius: 18,
        background: solid ? bg : 'transparent',
        border: solid ? 'none' : `1px solid ${RELAY_T.hair2}`,
        color: solid ? '#F8F4EA' : RELAY_T.ink,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: RELAY_T.sans, fontSize: 16, fontWeight: 500,
        letterSpacing: -0.1,
      }}>{primary}</div>
      {secondary && (
        <div style={{
          textAlign: 'center',
          fontFamily: RELAY_T.mono, fontSize: 11, color: RELAY_T.faint,
          letterSpacing: 0.3,
        }}>{secondary}</div>
      )}
    </div>
  );
}

// O1 — Welcome
function ScreenOnboardWelcome() {
  return (
    <div data-screen-label="O1 Welcome" style={{
      background: RELAY_T.bg, width: '100%', height: '100%',
      position: 'relative', overflow: 'hidden',
    }}>
      <RelayHeader status="offline" detail="not paired" />

      <div style={{ padding: '64px 28px 0' }}>
        <div style={{
          fontFamily: RELAY_T.serif, fontSize: 40, lineHeight: 1.1,
          color: RELAY_T.ink, letterSpacing: -0.7, textWrap: 'pretty',
        }}>
          Ein ruhiger Kanal{' '}
          <span style={{ color: RELAY_T.faint, fontStyle: 'italic' }}>
            zu dem, was zu Hause auf dich wartet.
          </span>
        </div>
        <div style={{
          marginTop: 24,
          fontFamily: RELAY_T.serif, fontSize: 17, lineHeight: 1.5,
          color: RELAY_T.muted, letterSpacing: -0.1, textWrap: 'pretty',
        }}>
          Relay ist ein Mikrofon. Was du sagst, geht über einen privaten
          Telegram-Bot an deine Claude-Code-Instanz zu Hause — Telegram
          siehst du nie, der Bot ist nur die Leitung.
        </div>

        <div style={{
          marginTop: 32, padding: '16px 18px', borderRadius: 14,
          border: `0.5px dashed ${RELAY_T.hair2}`,
        }}>
          <div style={{
            fontFamily: RELAY_T.mono, fontSize: 10, letterSpacing: 1.2,
            color: RELAY_T.faint, textTransform: 'uppercase', marginBottom: 12,
            display: 'flex', justifyContent: 'space-between',
          }}>
            <span>auf deinem Rechner · einmalig</span>
            <span style={{ color: RELAY_T.faint }}>~5 min</span>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 9 }}>
            {[
              ['1', 'Claude Code & Bun installiert'],
              ['2', 'Telegram-Bot via BotFather → Token'],
              ['3', <span><span style={{ fontFamily: RELAY_T.mono, fontSize: 12 }}>/plugin install telegram@claude-plugins-official</span></span>],
              ['4', <span>Mit <span style={{ fontFamily: RELAY_T.mono, fontSize: 12 }}>--channels</span> als Service laufen lassen</span>],
            ].map(([n, t], i) => (
              <div key={i} style={{
                display: 'flex', gap: 10, alignItems: 'flex-start',
                fontFamily: RELAY_T.serif, fontSize: 14, lineHeight: 1.45,
                color: RELAY_T.ink, letterSpacing: -0.05,
              }}>
                <span style={{
                  fontFamily: RELAY_T.mono, color: RELAY_T.faint, fontSize: 10.5,
                  paddingTop: 4, width: 12, flexShrink: 0,
                }}>{n}</span>
                <span style={{ flex: 1 }}>{t}</span>
              </div>
            ))}
          </div>
          <div style={{
            marginTop: 12, paddingTop: 10,
            borderTop: `0.5px solid ${RELAY_T.hair}`,
            fontFamily: RELAY_T.mono, fontSize: 10, color: RELAY_T.faint,
            letterSpacing: 0.3, lineHeight: 1.5,
          }}>
            Anleitung steht in der README · kein Tailscale, kein eigener Server
          </div>
        </div>
      </div>

      <OnboardBottom step={1} total={5} primary="Rechner ist bereit" secondary="sonst erst dort einrichten" />
    </div>
  );
}

// O2 — Bot eingeben (BotFather token / username)
function ScreenOnboardPairQR() {
  return (
    <div data-screen-label="O2 Bot" style={{
      background: RELAY_T.bg, width: '100%', height: '100%',
      position: 'relative', overflow: 'hidden',
    }}>
      <RelayHeader status="offline" detail="bot · setup" />

      <div style={{ padding: '14px 24px 0' }}>
        <div style={{
          fontFamily: RELAY_T.serif, fontSize: 28, lineHeight: 1.2,
          color: RELAY_T.ink, letterSpacing: -0.4, textWrap: 'pretty',
        }}>
          Dein Bot ist die Leitung.
        </div>
        <div style={{
          marginTop: 8,
          fontFamily: RELAY_T.serif, fontSize: 14.5, lineHeight: 1.5,
          color: RELAY_T.muted, letterSpacing: -0.05, fontStyle: 'italic',
          textWrap: 'pretty',
        }}>
          Gib den Username deines Telegram-Bots ein — den, den du via
          BotFather erstellt und auf deinem Rechner konfiguriert hast.
        </div>

        {/* Bot username input */}
        <div style={{ marginTop: 26 }}>
          <div style={{
            fontFamily: RELAY_T.mono, fontSize: 10, letterSpacing: 1.2,
            color: RELAY_T.faint, textTransform: 'uppercase', marginBottom: 8,
          }}>bot username</div>
          <div style={{
            padding: '14px 16px', borderRadius: 12,
            background: RELAY_T.paper,
            border: `1px solid ${RELAY_T.ink}`,
            display: 'flex', alignItems: 'center',
            fontFamily: RELAY_T.mono, fontSize: 16, color: RELAY_T.ink,
            letterSpacing: 0.2,
          }}>
            <span style={{ color: RELAY_T.faint, marginRight: 2 }}>@</span>
            mein_relay_bot
            <span style={{
              marginLeft: 4, width: 2, height: 18,
              background: RELAY_T.ink,
              animation: 'relay-caret 0.9s steps(2,end) infinite',
            }} />
          </div>
          <div style={{
            marginTop: 8,
            fontFamily: RELAY_T.mono, fontSize: 10, color: RELAY_T.faint,
            letterSpacing: 0.3,
          }}>
            findest du in BotFather · Format @name oder t.me/name
          </div>
        </div>

        {/* Where this came from — host setup recap */}
        <div style={{
          marginTop: 26, padding: '14px 16px', borderRadius: 12,
          background: RELAY_T.paper, border: `0.5px solid ${RELAY_T.hair2}`,
        }}>
          <div style={{
            fontFamily: RELAY_T.mono, fontSize: 10, color: RELAY_T.faint,
            letterSpacing: 0.5, marginBottom: 10, textTransform: 'uppercase',
            display: 'flex', justifyContent: 'space-between',
          }}>
            <span>auf deinem Rechner, vorher</span>
            <span>✓ erledigt?</span>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {[
              '/plugin install telegram@claude-plugins-official',
              '/telegram:configure <token>',
              'claude --channels plugin:telegram@…',
            ].map((line, i) => (
              <div key={i} style={{
                fontFamily: RELAY_T.mono, fontSize: 11.5, color: RELAY_T.ink,
                letterSpacing: 0.15, lineHeight: 1.4,
                overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
              }}>
                <span style={{ color: RELAY_T.faint }}>$ </span>{line}
              </div>
            ))}
          </div>
        </div>

        <div style={{
          marginTop: 14,
          fontFamily: RELAY_T.mono, fontSize: 10.5, color: RELAY_T.faint,
          letterSpacing: 0.3, display: 'flex', alignItems: 'center', gap: 8,
        }}>
          <span style={{
            width: 5, height: 5, borderRadius: 9999, background: RELAY_T.faint,
          }} />
          token lieber direkt eintippen?
          <span style={{ color: RELAY_T.ink, borderBottom: `0.5px solid ${RELAY_T.ink}` }}>
            Token statt Username
          </span>
        </div>
      </div>

      <OnboardBottom
        step={2} total={5}
        primary="Nachricht schicken"
        secondary="Relay schickt /start an den Bot und wartet auf den Pairing-Code"
      />
    </div>
  );
}

// O3 — Pairing-Code · App hat /start an Bot geschickt und wartet
function ScreenOnboardPairManual() {
  const code = 'OAK · RIVER · 7142';
  return (
    <div data-screen-label="O3 Pairing code" style={{
      background: RELAY_T.bg, width: '100%', height: '100%',
      position: 'relative', overflow: 'hidden',
    }}>
      <RelayHeader status="offline" detail="warte auf claude code" />

      <div style={{ padding: '14px 24px 0' }}>
        <div style={{
          fontFamily: RELAY_T.serif, fontSize: 28, lineHeight: 1.2,
          color: RELAY_T.ink, letterSpacing: -0.4,
          textWrap: 'pretty',
        }}>
          Sag deiner Claude, dass das du bist.
        </div>
        <div style={{
          marginTop: 8,
          fontFamily: RELAY_T.serif, fontSize: 14.5, lineHeight: 1.5,
          color: RELAY_T.muted, letterSpacing: -0.05, fontStyle: 'italic',
        }}>
          Relay hat eine Nachricht an deinen Bot geschickt. Dein Rechner hat
          geantwortet — mit diesem Code:
        </div>

        {/* The code — big, monospaced, paper card */}
        <div style={{
          marginTop: 22, padding: '22px 18px',
          borderRadius: 16,
          background: RELAY_T.paper,
          border: `0.5px solid ${RELAY_T.hair2}`,
          textAlign: 'center',
        }}>
          <div style={{
            fontFamily: RELAY_T.mono, fontSize: 10, letterSpacing: 1.2,
            color: RELAY_T.faint, textTransform: 'uppercase', marginBottom: 12,
          }}>pairing code · 90 s gültig</div>
          <div style={{
            fontFamily: RELAY_T.mono, fontSize: 22, letterSpacing: 2,
            color: RELAY_T.ink, fontWeight: 500,
          }}>{code}</div>
        </div>

        {/* Command to paste into Claude Code */}
        <div style={{ marginTop: 22 }}>
          <div style={{
            fontFamily: RELAY_T.mono, fontSize: 10, letterSpacing: 1.2,
            color: RELAY_T.faint, textTransform: 'uppercase', marginBottom: 8,
            display: 'flex', justifyContent: 'space-between',
          }}>
            <span>tipp das in claude code</span>
            <span style={{ color: RELAY_T.ink, textTransform: 'none', letterSpacing: 0.3 }}>copy</span>
          </div>
          <div style={{
            padding: '14px 14px', borderRadius: 12,
            background: RELAY_T.ink, color: '#F8F4EA',
            fontFamily: RELAY_T.mono, fontSize: 12.5, lineHeight: 1.5,
            letterSpacing: 0.1,
            overflow: 'hidden',
          }}>
            <span style={{ color: 'rgba(248,244,234,0.45)' }}>&gt; </span>
            /telegram:access pair <br/>
            <span style={{ marginLeft: 14 }}>oak-river-7142</span>
          </div>
        </div>

        {/* Listening state */}
        <div style={{
          marginTop: 22, padding: '14px 16px', borderRadius: 12,
          border: `0.5px dashed ${RELAY_T.hair2}`,
          display: 'flex', alignItems: 'center', gap: 12,
        }}>
          <span style={{
            width: 8, height: 8, borderRadius: 9999, background: RELAY_T.amber,
            boxShadow: `0 0 0 5px ${RELAY_T.amber}22`,
            flexShrink: 0,
          }} />
          <div style={{ flex: 1 }}>
            <div style={{
              fontFamily: RELAY_T.serif, fontSize: 14, lineHeight: 1.4,
              color: RELAY_T.ink, letterSpacing: -0.05,
            }}>
              Warte auf Bestätigung vom Rechner…
            </div>
            <div style={{
              fontFamily: RELAY_T.mono, fontSize: 10, color: RELAY_T.faint,
              letterSpacing: 0.3, marginTop: 3,
            }}>
              schliesst von selbst, sobald der Code erkannt ist
            </div>
          </div>
        </div>
      </div>

      <OnboardBottom
        step={3} total={5}
        primary="neuen Code anfragen"
        primaryVariant="ghost"
        secondary="Rechner nicht erreichbar? Bot-Username prüfen"
      />
    </div>
  );
}

// O4 — Paired
function ScreenOnboardPaired() {
  return (
    <div data-screen-label="O4 Paired" style={{
      background: RELAY_T.bg, width: '100%', height: '100%',
      position: 'relative', overflow: 'hidden',
    }}>
      <RelayHeader status="connected" detail="verbunden" />

      <div style={{ padding: '48px 28px 0' }}>
        <div style={{
          width: 56, height: 56, borderRadius: 9999,
          border: `1.25px solid ${RELAY_T.sage}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="20" height="20" viewBox="0 0 22 22" fill="none">
            <path d="M4 11.5l5 5L18 6" stroke={RELAY_T.sage} strokeWidth="1.5"
              strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>

        <div style={{
          marginTop: 22,
          fontFamily: RELAY_T.serif, fontSize: 36, color: RELAY_T.ink,
          letterSpacing: -0.6, lineHeight: 1.05,
        }}>
          Verbunden.
        </div>
        <div style={{
          marginTop: 10,
          fontFamily: RELAY_T.serif, fontSize: 17, lineHeight: 1.5,
          color: RELAY_T.muted, letterSpacing: -0.1, fontStyle: 'italic',
          textWrap: 'pretty',
        }}>
          Dein Bot ist gepaart, Claude Code hört zu. Erster Round-trip
          war 412&nbsp;ms — Telegram ist halt nicht der schnellste, aber
          stabil.
        </div>

        <div style={{
          marginTop: 32, paddingTop: 16,
          borderTop: `0.5px solid ${RELAY_T.hair}`,
          display: 'flex', flexDirection: 'column', gap: 12,
        }}>
          {[
            ['bot',          '@mein_relay_bot'],
            ['chat-id',      '8 421 9·· ····'],
            ['channel',      'telegram@claude-plugins-official'],
            ['claude code',  'up · 4d 11h'],
            ['mcps',         '4 · obsidian · ticktick · home · gmail'],
          ].map(([k, v]) => (
            <div key={k} style={{
              display: 'flex', justifyContent: 'space-between', gap: 12,
              fontFamily: RELAY_T.mono, fontSize: 11.5, letterSpacing: 0.2,
            }}>
              <span style={{ color: RELAY_T.faint }}>{k}</span>
              <span style={{
                color: RELAY_T.ink, textAlign: 'right',
                overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                maxWidth: '65%',
              }}>{v}</span>
            </div>
          ))}
        </div>

        {/* whisper download */}
        <div style={{ marginTop: 26 }}>
          <div style={{
            display: 'flex', justifyContent: 'space-between',
            fontFamily: RELAY_T.mono, fontSize: 11, letterSpacing: 0.2,
            color: RELAY_T.muted, marginBottom: 8,
          }}>
            <span>whisper base · multilingual</span>
            <span>97 / 152 MB</span>
          </div>
          <div style={{
            height: 3, background: RELAY_T.hair, borderRadius: 9999,
            overflow: 'hidden',
          }}>
            <div style={{
              width: '64%', height: '100%', background: RELAY_T.sage,
            }} />
          </div>
        </div>
      </div>

      <OnboardBottom step={4} total={5} primary="weiter" />
    </div>
  );
}

// O5 — Action button / Trigger setup
function TriggerOption({ icon, label, hint, selected }) {
  return (
    <div style={{
      padding: '14px 16px', borderRadius: 14,
      border: `${selected ? 1.5 : 0.5}px solid ${selected ? RELAY_T.ink : RELAY_T.hair2}`,
      background: selected ? RELAY_T.paper : 'transparent',
      display: 'flex', alignItems: 'center', gap: 14,
    }}>
      <div style={{
        width: 36, height: 36, borderRadius: 10,
        background: selected ? RELAY_T.ink : 'transparent',
        color: selected ? '#F8F4EA' : RELAY_T.ink,
        border: selected ? 'none' : `0.5px solid ${RELAY_T.hair2}`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
      }}>{icon}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontFamily: RELAY_T.sans, fontSize: 15, fontWeight: 500,
          color: RELAY_T.ink, letterSpacing: -0.1,
        }}>{label}</div>
        <div style={{
          fontFamily: RELAY_T.mono, fontSize: 10.5, color: RELAY_T.faint,
          letterSpacing: 0.2, marginTop: 2,
        }}>{hint}</div>
      </div>
      {selected && (
        <svg width="16" height="16" viewBox="0 0 22 22" fill="none">
          <path d="M4 11.5l5 5L18 6" stroke={RELAY_T.ink} strokeWidth="1.7"
            strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      )}
    </div>
  );
}

function ScreenOnboardTrigger() {
  // iPhone silhouette with Action Button glowing
  return (
    <div data-screen-label="O5 Trigger" style={{
      background: RELAY_T.bg, width: '100%', height: '100%',
      position: 'relative', overflow: 'hidden',
    }}>
      <RelayHeader status="connected" detail="last step" />

      <div style={{ padding: '20px 28px 0' }}>
        <div style={{
          fontFamily: RELAY_T.serif, fontSize: 30, lineHeight: 1.18,
          color: RELAY_T.ink, letterSpacing: -0.5, textWrap: 'pretty',
        }}>
          Wie öffnest du Relay?
        </div>
        <div style={{
          marginTop: 8,
          fontFamily: RELAY_T.serif, fontSize: 15, lineHeight: 1.5,
          color: RELAY_T.muted, letterSpacing: -0.05, fontStyle: 'italic',
        }}>
          Wähl einen Trigger. Die anderen kannst du später auch noch dazu legen.
        </div>

        {/* iPhone silhouette w/ Action Button highlight */}
        <div style={{
          marginTop: 22, marginBottom: 24,
          display: 'flex', justifyContent: 'center',
        }}>
          <svg width="120" height="100" viewBox="0 0 120 100" fill="none">
            {/* phone outline (left side, edge view) */}
            <rect x="28" y="6" width="64" height="88" rx="14"
              stroke={RELAY_T.hair2} strokeWidth="1" fill={RELAY_T.paper}/>
            {/* screen */}
            <rect x="33" y="11" width="54" height="78" rx="9"
              fill={RELAY_T.bg} stroke="none"/>
            {/* action button */}
            <rect x="25" y="30" width="4" height="14" rx="1.5"
              fill={RELAY_T.amber}/>
            <rect x="25" y="30" width="4" height="14" rx="1.5"
              fill={RELAY_T.amber} opacity="0.3"
              style={{ filter: 'blur(6px)' }}/>
            {/* volume buttons (faint) */}
            <rect x="91" y="28" width="4" height="9" rx="1.5"
              fill={RELAY_T.hair2}/>
            <rect x="91" y="42" width="4" height="14" rx="1.5"
              fill={RELAY_T.hair2}/>
            {/* label line */}
            <line x1="22" y1="37" x2="8" y2="37" stroke={RELAY_T.amber} strokeWidth="0.75"/>
            <text x="2" y="34" fontFamily={RELAY_T.mono} fontSize="6"
              fill={RELAY_T.amber} letterSpacing="0.5">action</text>
          </svg>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <TriggerOption
            selected
            icon={<svg width="14" height="14" viewBox="0 0 14 14"><rect x="6" y="2" width="2" height="10" rx="1" fill="currentColor"/></svg>}
            label="Action Button"
            hint="ein Druck · öffnet & nimmt auf"
          />
          <TriggerOption
            icon={<svg width="16" height="16" viewBox="0 0 16 16" fill="none"><circle cx="5" cy="9" r="3" stroke="currentColor" strokeWidth="1.2"/><circle cx="11" cy="9" r="3" stroke="currentColor" strokeWidth="1.2"/><path d="M5 9V4M11 9V4" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round"/></svg>}
            label="AirPods · Stem long-press"
            hint="im Hosentaschen-Modus, hands-free"
          />
          <TriggerOption
            icon={<svg width="14" height="14" viewBox="0 0 14 14" fill="none"><rect x="2" y="1" width="10" height="12" rx="2" stroke="currentColor" strokeWidth="1.2"/><circle cx="7" cy="10.5" r="1" fill="currentColor"/></svg>}
            label="Lock-Screen Shortcut"
            hint="aus der unteren rechten Ecke"
          />
        </div>
      </div>

      <OnboardBottom
        step={5} total={5}
        primary="Shortcut installieren"
        secondary="oder später · Settings → Trigger"
      />
    </div>
  );
}

// Mono chip for a spoken trigger phrase
function TriggerChip({ children, accent }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      fontFamily: RELAY_T.mono, fontSize: 11, letterSpacing: 0.2,
      color: accent || RELAY_T.ink,
      background: RELAY_T.bg,
      border: `0.5px solid ${RELAY_T.hair2}`,
      borderRadius: 5, padding: '2px 7px 1.5px',
      whiteSpace: 'nowrap',
    }}>
      <span style={{ opacity: 0.45, marginRight: 0 }}>“</span>
      {children}
      <span style={{ opacity: 0.45 }}>”</span>
    </span>
  );
}

// A single command card — verb at top in display type, aliases as chips below
function CommandCard({ verb, action, accent, triggers, last }) {
  return (
    <div style={{
      padding: '20px 24px 22px',
      borderBottom: last ? 'none' : `0.5px solid ${RELAY_T.hair}`,
      display: 'flex', flexDirection: 'column', gap: 12,
    }}>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 12 }}>
        <div style={{
          fontFamily: RELAY_T.serif, fontSize: 26,
          color: accent, letterSpacing: -0.4, lineHeight: 1,
        }}>{verb}</div>
        <div style={{
          flex: 1,
          fontFamily: RELAY_T.serif, fontSize: 14, lineHeight: 1.4,
          color: RELAY_T.muted, letterSpacing: -0.05, fontStyle: 'italic',
        }}>{action}</div>
      </div>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
        {triggers.map((t, i) => <TriggerChip key={i} accent={accent}>{t}</TriggerChip>)}
        <span style={{
          display: 'inline-flex', alignItems: 'center',
          fontFamily: RELAY_T.mono, fontSize: 11, color: RELAY_T.faint,
          border: `0.5px dashed ${RELAY_T.hair2}`, borderRadius: 5,
          padding: '2px 8px 1.5px',
        }}>+ alias</span>
      </div>
    </div>
  );
}

// 9. COMMANDS LIBRARY — v1: two built-ins, aliases editable
function ScreenCommands() {
  return (
    <div data-screen-label="09 Commands" style={{
      background: RELAY_T.bg, width: '100%', height: '100%',
      position: 'relative', overflow: 'hidden',
    }}>
      <RelayHeader status="connected" detail="commands · 2" />

      <div style={{ padding: '8px 0 130px' }}>
        <div style={{
          padding: '4px 24px 22px',
          fontFamily: RELAY_T.serif, fontSize: 17, lineHeight: 1.45,
          color: RELAY_T.muted, letterSpacing: -0.1, fontStyle: 'italic',
          textWrap: 'pretty',
        }}>
          Zwei Worte, die das Aufnehmen beenden. Eins schickt los, eins
          vergisst alles. Sprich Aliase frei dazu.
        </div>

        <div style={{
          background: RELAY_T.paper,
          borderTop: `0.5px solid ${RELAY_T.hair2}`,
          borderBottom: `0.5px solid ${RELAY_T.hair2}`,
        }}>
          <CommandCard
            verb="send."
            accent={RELAY_T.ink}
            action="Schliesst die Aufnahme sofort ab und schickt sie an Claude."
            triggers={['send', 'fertig', 'schick’s ab', 'abschicken']}
          />
          <CommandCard
            verb="vergessen."
            accent={RELAY_T.rust}
            action="Verwirft die Aufnahme lokal — nichts wird gesendet, nichts gespeichert."
            triggers={['vergessen', 'vergiss das', 'scratch that']}
            last
          />
        </div>

        <div style={{
          margin: '18px 24px 0',
          padding: '14px 16px', borderRadius: 12,
          border: `0.5px dashed ${RELAY_T.hair2}`,
          display: 'flex', alignItems: 'flex-start', gap: 10,
        }}>
          <div style={{
            fontFamily: RELAY_T.mono, fontSize: 10, color: RELAY_T.faint,
            letterSpacing: 1.2, textTransform: 'uppercase', paddingTop: 1,
          }}>v1</div>
          <div style={{
            flex: 1,
            fontFamily: RELAY_T.serif, fontSize: 13.5, lineHeight: 1.45,
            color: RELAY_T.muted, letterSpacing: -0.05,
          }}>
            Mehr ist nicht eingebaut. Routing macht Claude anhand des Inhalts,
            nicht das Telefon.
          </div>
        </div>
      </div>

      <div style={{
        position: 'absolute', bottom: 34, left: 24, right: 24,
        display: 'flex', alignItems: 'center', gap: 10,
        fontFamily: RELAY_T.mono, fontSize: 10.5, color: RELAY_T.faint,
        letterSpacing: 0.3,
      }}>
        <span style={{ width: 6, height: 6, borderRadius: 9999, background: RELAY_T.sage }} />
        matched on-device · never leaves the phone unless it fires
      </div>
    </div>
  );
}

// 10. EDIT COMMAND — only aliases are editable; v1 has no kind to pick
function ScreenCommandEdit() {
  return (
    <div data-screen-label="10 Edit command" style={{
      background: RELAY_T.bg, width: '100%', height: '100%',
      position: 'relative', overflow: 'hidden',
    }}>
      <RelayHeader status="connected" detail="edit · vergessen" />

      <div style={{ padding: '14px 24px 40px' }}>
        {/* Big verb header */}
        <div style={{
          fontFamily: RELAY_T.serif, fontSize: 44, color: RELAY_T.rust,
          letterSpacing: -0.8, lineHeight: 1,
        }}>vergessen.</div>
        <div style={{
          marginTop: 10,
          fontFamily: RELAY_T.serif, fontSize: 16, lineHeight: 1.45,
          color: RELAY_T.muted, letterSpacing: -0.1, fontStyle: 'italic',
          textWrap: 'pretty',
        }}>
          Verwirft die Aufnahme lokal. Nichts geht raus, nichts steht in der
          Liste, kein Ton.
        </div>

        {/* Trigger phrases editor */}
        <div style={{ marginTop: 30 }}>
          <div style={{
            fontFamily: RELAY_T.mono, fontSize: 10, letterSpacing: 1.2,
            color: RELAY_T.faint, textTransform: 'uppercase', marginBottom: 12,
          }}>aliases</div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
            <TriggerChip accent={RELAY_T.rust}>vergessen</TriggerChip>
            <TriggerChip accent={RELAY_T.rust}>vergiss das</TriggerChip>
            <TriggerChip accent={RELAY_T.rust}>scratch that</TriggerChip>
            <TriggerChip accent={RELAY_T.rust}>lösch das</TriggerChip>
            <span style={{
              display: 'inline-flex', alignItems: 'center', gap: 4,
              fontFamily: RELAY_T.mono, fontSize: 11, color: RELAY_T.faint,
              border: `0.5px dashed ${RELAY_T.hair2}`, borderRadius: 5,
              padding: '2px 8px 1.5px',
            }}>+ alias</span>
          </div>
          <div style={{
            marginTop: 10,
            fontFamily: RELAY_T.mono, fontSize: 10, color: RELAY_T.faint,
            letterSpacing: 0.3,
          }}>
            matched as the last word(s) of a capture · case-insensitive
          </div>
        </div>

        {/* Preview */}
        <div style={{ marginTop: 30 }}>
          <div style={{
            fontFamily: RELAY_T.mono, fontSize: 10, letterSpacing: 1.2,
            color: RELAY_T.faint, textTransform: 'uppercase', marginBottom: 10,
          }}>so klingt’s in der Aufnahme</div>
          <div style={{
            padding: '16px 18px', borderRadius: 14,
            background: RELAY_T.paper,
            border: `0.5px solid ${RELAY_T.hair2}`,
          }}>
            <div style={{
              fontFamily: RELAY_T.serif, fontSize: 16, lineHeight: 1.5,
              color: RELAY_T.muted, letterSpacing: -0.1,
            }}>
              „Idee für Relay: vielleicht statt einem Shared Secret eher ein
              kurzer QR-Code-Pairing… ach,{' '}
              <span style={{
                background: `${RELAY_T.rust}1c`,
                borderBottom: `1.25px solid ${RELAY_T.rust}`,
                padding: '0 4px',
                color: RELAY_T.rust,
                fontStyle: 'normal',
              }}>vergiss das</span>.“
            </div>
            <div style={{
              display: 'flex', alignItems: 'center', gap: 8, marginTop: 12,
              fontFamily: RELAY_T.mono, fontSize: 10, color: RELAY_T.muted,
              letterSpacing: 0.3,
            }}>
              <span style={{ color: RELAY_T.rust }}>● matched</span>
              <span>→ capture dropped · 0 bytes sent</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// 11. RECORDING — “send” command detected at the end
function ScreenRecordingCommand() {
  return (
    <div data-screen-label="11 Recording · send" style={{
      background: RELAY_T.bg, width: '100%', height: '100%',
      position: 'relative', overflow: 'hidden',
    }}>
      <RelayHeader status="recording" detail="recording · 0:09" />

      <div style={{ padding: '32px 28px 200px' }}>
        <div style={{
          fontFamily: RELAY_T.mono, fontSize: 10, letterSpacing: 1.2,
          color: RELAY_T.faint, textTransform: 'uppercase', marginBottom: 14,
        }}>transcript · whisper base</div>

        <div style={{
          fontFamily: RELAY_T.serif, fontSize: 22, lineHeight: 1.42,
          color: RELAY_T.ink, letterSpacing: -0.2,
          textWrap: 'pretty',
        }}>
          Mit Jan über das Pairing reden — vielleicht ein QR-Flow statt
          Shared Secret.{' '}
          <span style={{
            display: 'inline-block',
            background: `${RELAY_T.ink}10`,
            borderBottom: `1.5px solid ${RELAY_T.ink}`,
            padding: '0 6px',
            borderRadius: 2,
            fontStyle: 'normal',
          }}>
            Send.
          </span>
        </div>

        <div style={{
          marginTop: 18,
          display: 'flex', alignItems: 'center', gap: 8,
          fontFamily: RELAY_T.mono, fontSize: 11, color: RELAY_T.muted,
          letterSpacing: 0.2,
        }}>
          <span style={{ width: 6, height: 6, borderRadius: 9999, background: RELAY_T.ink }} />
          command matched · closing capture
        </div>
      </div>

      {/* bottom: waveform settling toward zero, ink button (matches Home tap-to-talk) */}
      <div style={{
        position: 'absolute', bottom: 34, left: 24, right: 24,
        display: 'flex', flexDirection: 'column', gap: 14,
      }}>
        <Waveform active amp={0.2} tint={RELAY_T.ink} />
        <div style={{
          width: '100%', height: 64, borderRadius: 18,
          background: RELAY_T.ink,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: '#F8F4EA',
          fontFamily: RELAY_T.sans, fontSize: 16, fontWeight: 500,
          letterSpacing: -0.1,
        }}>
          sending…
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// export
// ─────────────────────────────────────────────────────────────
Object.assign(window, {
  ScreenHome, ScreenListening, ScreenRecording, ScreenAck,
  ScreenSpeak, ScreenSettings, ScreenConnection, ScreenFirstRun,
  ScreenCommands, ScreenCommandEdit, ScreenRecordingCommand,
  ScreenOnboardWelcome, ScreenOnboardPairQR, ScreenOnboardPairManual,
  ScreenOnboardPaired, ScreenOnboardTrigger,
  RELAY_T,
});
