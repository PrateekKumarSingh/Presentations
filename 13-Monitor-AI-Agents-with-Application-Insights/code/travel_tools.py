"""Travel tools for AI agent demo.

This module uses free public APIs where possible:
- Weather: Open Meteo (no API key)
- Web search: DuckDuckGo Instant Answer API (no API key)

Other tools remain mocked for demo completeness.
"""

import random
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional, cast
import json
import requests  # type: ignore[import-untyped]


# =============================================================================
# Weather Tool
# =============================================================================

def _weather_code_to_text(code: int) -> str:
    code_map = {
        0: "Clear sky",
        1: "Mainly clear",
        2: "Partly cloudy",
        3: "Overcast",
        45: "Fog",
        48: "Depositing rime fog",
        51: "Light drizzle",
        53: "Moderate drizzle",
        55: "Dense drizzle",
        61: "Slight rain",
        63: "Moderate rain",
        65: "Heavy rain",
        71: "Slight snow",
        73: "Moderate snow",
        75: "Heavy snow",
        80: "Rain showers",
        81: "Heavy rain showers",
        95: "Thunderstorm",
    }
    return code_map.get(code, "Unknown")


def _fallback_weather(city: str, travel_dates: str) -> Dict[str, Any]:
    """Fallback when external API is unavailable."""
    return {
        "city": city,
        "travel_dates": travel_dates,
        "temp_avg": 12,
        "temp_range": (8, 16),
        "conditions": "Partly cloudy",
        "precipitation_probability": 20,
        "wind_speed": 10,
        "humidity": 60,
        "best_time": "10:00-16:00",
        "packing_tips": ["Light jacket", "Comfortable shoes"],
        "source": "fallback",
        "timestamp": datetime.now().isoformat(),
    }


def get_weather(city: str, travel_dates: str) -> Dict[str, Any]:
    """Get weather from Open-Meteo using city geocoding (free, no API key)."""
    try:
        geocode = requests.get(
            "https://geocoding-api.open-meteo.com/v1/search",
            params={"name": city, "count": 1, "language": "en", "format": "json"},
            timeout=10,
        )
        geocode.raise_for_status()
        results = geocode.json().get("results", [])
        if not results:
            return _fallback_weather(city, travel_dates)

        lat = results[0]["latitude"]
        lon = results[0]["longitude"]
        resolved_city = results[0].get("name", city)

        weather = requests.get(
            "https://api.open-meteo.com/v1/forecast",
            params={
                "latitude": lat,
                "longitude": lon,
                "current": "temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code",
                "daily": "temperature_2m_max,temperature_2m_min,precipitation_probability_max,weather_code",
                "timezone": "auto",
                "forecast_days": 3,
            },
            timeout=10,
        )
        weather.raise_for_status()
        payload = weather.json()

        current = payload.get("current", {})
        daily = payload.get("daily", {})
        weather_code = current.get("weather_code", 0)

        temp_min = daily.get("temperature_2m_min", [current.get("temperature_2m", 0)])[0]
        temp_max = daily.get("temperature_2m_max", [current.get("temperature_2m", 0)])[0]
        precip = daily.get("precipitation_probability_max", [0])[0]

        return {
            "city": resolved_city,
            "travel_dates": travel_dates,
            "temp_avg": round((temp_min + temp_max) / 2, 1),
            "temp_range": (round(temp_min, 1), round(temp_max, 1)),
            "conditions": _weather_code_to_text(weather_code),
            "precipitation_probability": precip,
            "wind_speed": current.get("wind_speed_10m", 0),
            "humidity": current.get("relative_humidity_2m", 0),
            "best_time": "Morning to afternoon",
            "packing_tips": ["Light layers", "Comfortable shoes", "Umbrella if needed"],
            "source": "open-meteo",
            "timestamp": datetime.now().isoformat(),
        }
    except Exception:
        return _fallback_weather(city, travel_dates)


def web_search(query: str, limit: int = 5) -> List[Dict[str, Any]]:
    """Free web search via DuckDuckGo Instant Answer API (no API key)."""
    try:
        response = requests.get(
            "https://api.duckduckgo.com/",
            params={
                "q": query,
                "format": "json",
                "no_html": 1,
                "skip_disambig": 1,
                "no_redirect": 1,
            },
            timeout=10,
        )
        response.raise_for_status()
        data = response.json()

        output: List[Dict[str, Any]] = []

        abstract = data.get("AbstractText")
        abstract_url = data.get("AbstractURL")
        heading = data.get("Heading")
        if abstract:
            output.append(
                {
                    "title": heading or query,
                    "snippet": abstract,
                    "url": abstract_url or "",
                    "source": "duckduckgo-abstract",
                }
            )

        related = data.get("RelatedTopics", [])
        for item in related:
            if isinstance(item, dict) and item.get("Text"):
                output.append(
                    {
                        "title": item.get("Text", "").split(" - ")[0],
                        "snippet": item.get("Text", ""),
                        "url": item.get("FirstURL", ""),
                        "source": "duckduckgo-related",
                    }
                )
            if len(output) >= limit:
                break

        if not output:
            output.append(
                {
                    "title": "No direct result",
                    "snippet": f"No concise result found for '{query}'.",
                    "url": "",
                    "source": "duckduckgo",
                }
            )

        return output[:limit]
    except Exception:
        return [
            {
                "title": "Search unavailable",
                "snippet": f"Unable to fetch web search results for '{query}'.",
                "url": "",
                "source": "fallback",
            }
        ]


# =============================================================================
# Hotel Search Tool
# =============================================================================

def search_hotels(
    city: str,
    check_in_date: str,
    check_out_date: str,
    max_price_per_night: int = 5000,
    limit: int = 200
) -> List[Dict[str, Any]]:
    """
    Search for hotels in a city.
    
    Args:
        city: City name
        check_in_date: Check-in date (e.g., "2024-12-01")
        check_out_date: Check-out date
        max_price_per_night: Maximum price per night (JPY for Tokyo)
        limit: Max results to return (default 200 - this is what causes the problem!)
    
    Returns:
        List of hotel options
    """
    # Mock hotels for Tokyo
    tokyo_hotels = [
        {
            "id": f"hotel_{i}",
            "name": f"Hotel {'Premium' if i % 3 == 0 else 'Business' if i % 3 == 1 else 'Economy'} Tokyo {i}",
            "location": random.choice(["Shibuya", "Shinjuku", "Minato", "Chiyoda", "Taito"]),
            "rating": round(random.uniform(3.5, 5.0), 1),
            "reviews": random.randint(50, 2000),
            "price_per_night_jpy": random.randint(8000, 60000),
            "amenities": random.sample(
                ["WiFi", "Breakfast", "Gym", "Restaurant", "Room Service", "Laundry", "Parking"],
                k=random.randint(3, 5)
            ),
            "distance_to_center_km": round(random.uniform(0.5, 15.0), 1),
            "rooms_available": random.randint(1, 20),
            "booking_url": f"https://booking.example.com/hotel_{i}"
        }
        for i in range(1, limit + 1)
    ]
    
    # Filter by price
    filtered = [
        h
        for h in tokyo_hotels
        if cast(int, h["price_per_night_jpy"]) <= max_price_per_night
    ]
    
    return filtered[:limit]


# =============================================================================
# Flight Search Tool
# =============================================================================

def search_flights(
    origin: str,
    destination: str,
    departure_date: str,
    return_date: Optional[str] = None,
    passengers: int = 1
) -> List[Dict[str, Any]]:
    """
    Search for flights.
    
    Args:
        origin: Origin city code (e.g., "SFO")
        destination: Destination city code (e.g., "NRT" for Tokyo)
        departure_date: Departure date
        return_date: Return date (for round trips)
        passengers: Number of passengers
    
    Returns:
        List of flight options
    """
    # Mock flight data
    flights = []
    airlines = ["ANA", "JAL", "United", "American", "Cathay Pacific"]
    
    for i in range(12):  # Return 12 flight options
        departure_hour = 6 + (i % 24)
        flight = {
            "id": f"flight_{i}",
            "airline": random.choice(airlines),
            "flight_number": f"XX{random.randint(100, 999)}",
            "departure": f"{departure_date} {departure_hour:02d}:00",
            "arrival": f"{departure_date} {(departure_hour + 14) % 24:02d}:00 (+1 day)",
            "duration_hours": 14,
            "price_usd": random.randint(600, 1800) * passengers,
            "seats_available": random.randint(1, 50),
            "stops": random.choice([0, 1]),
            "aircraft": random.choice(["Boeing 787", "Airbus A380", "Boeing 777"]),
            "booking_url": f"https://flights.example.com/flight_{i}"
        }
        flights.append(flight)
    
    return flights


# =============================================================================
# Activities Search Tool
# =============================================================================

def search_activities(
    city: str,
    category: str = "all",
    limit: int = 50
) -> List[Dict[str, Any]]:
    """
    Search for activities and attractions.
    
    Args:
        city: City name
        category: Activity category ("all", "museums", "outdoor", "food", "nightlife")
        limit: Max results
    
    Returns:
        List of activities
    """
    # Mock activities for Tokyo
    all_activities = [
        {
            "id": f"activity_{i}",
            "name": random.choice([
                "Senso-ji Temple",
                "Tsukiji Outer Market",
                "Tokyo National Museum",
                "Meiji Shrine",
                "Shibuya Crossing Tour",
                "Akihabara Electronics Tour",
                "Harajuku Fashion Walk",
                "Sumida River Cruise",
                "Gonpachi Nishi Azabu",
                "Pokemon Center",
                "Studio Ghibli Museum",
                "Teamlab Borderless",
                "Tokyo Skytree",
                "Imperial Palace East Gardens",
                "Shinjuku Gyoen",
                "Yokocho Memory Lane",
                "Ramen cooking class",
                "Sushi making experience"
            ]),
            "category": random.choice(["museums", "outdoor", "food", "nightlife", "shopping"]),
            "rating": round(random.uniform(4.0, 5.0), 1),
            "reviews": random.randint(100, 5000),
            "price_jpy": random.choice([0, 1000, 2000, 3000, 5000, 10000]),
            "duration": random.choice(["1 hour", "2 hours", "half day", "full day"]),
            "best_time": random.choice(["Morning", "Afternoon", "Evening", "Anytime"]),
            "booking_url": f"https://activities.example.com/activity_{i}"
        }
        for i in range(1, limit + 1)
    ]
    
    # Filter by category if specified
    if category != "all":
        activities = [a for a in all_activities if a["category"] == category]
    else:
        activities = all_activities
    
    return activities[:limit]


# =============================================================================
# Tool Description (for LLM)
# =============================================================================

TOOL_DESCRIPTIONS = {
    "get_weather": {
        "description": "Get weather forecast from Open-Meteo (free, no API key)",
        "parameters": {
            "city": "City name (e.g., Tokyo, Paris, Sydney)",
            "travel_dates": "Travel dates as string (e.g., December 1-5)"
        }
    },
    "web_search": {
        "description": "Search the web using DuckDuckGo Instant Answer API (free, no API key)",
        "parameters": {
            "query": "Search query text",
            "limit": "Maximum results to return"
        }
    },
    "search_hotels": {
        "description": "Search for hotels in a city with filters",
        "parameters": {
            "city": "City name",
            "check_in_date": "Check-in date (YYYY-MM-DD)",
            "check_out_date": "Check-out date (YYYY-MM-DD)",
            "max_price_per_night": "Max price per night in JPY",
            "limit": "Max results to return (WARNING: large limits use many tokens!)"
        }
    },
    "search_flights": {
        "description": "Search for flights",
        "parameters": {
            "origin": "Origin city code (SFO, LAX, etc.)",
            "destination": "Destination city code (NRT, HND, etc.)",
            "departure_date": "Departure date (YYYY-MM-DD)",
            "return_date": "Return date for round trips",
            "passengers": "Number of passengers"
        }
    },
    "search_activities": {
        "description": "Search for activities and attractions",
        "parameters": {
            "city": "City name",
            "category": "Category (all, museums, outdoor, food, nightlife)",
            "limit": "Max results"
        }
    }
}


# =============================================================================
# Utility Functions
# =============================================================================

def get_tool_by_name(tool_name: str):
    """Get tool callable by name."""
    tools = {
        "get_weather": get_weather,
        "web_search": web_search,
        "search_hotels": search_hotels,
        "search_flights": search_flights,
        "search_activities": search_activities,
    }
    return tools.get(tool_name)


def format_tool_results(tool_name: str, results: Any) -> str:
    """Format tool results as a string for LLM consumption."""
    if isinstance(results, list):
        if not results:
            return f"No results found from {tool_name}."
        
        # Limit description to first 3 results (to save tokens)
        summary = f"Found {len(results)} items from {tool_name}. Top 3:\n"
        for item in results[:3]:
            if "name" in item:
                summary += f"  - {item['name']} (Rating: {item.get('rating', 'N/A')})\n"
            else:
                summary += f"  - {json.dumps(item, indent=2)}\n"
        
        return summary
    else:
        return json.dumps(results, indent=2)


if __name__ == "__main__":
    # Test tools
    print("=== WEATHER ===")
    weather = get_weather("Tokyo", "December 1-5")
    print(json.dumps(weather, indent=2))

    print("\n=== WEB SEARCH ===")
    search = web_search("best neighborhoods to stay in Tokyo", limit=3)
    print(json.dumps(search, indent=2))
    
    print("\n=== HOTELS (First 3) ===")
    hotels = search_hotels("Tokyo", "2024-12-01", "2024-12-05", limit=3)
    print(json.dumps(hotels[:3], indent=2))
    
    print(f"\n=== HOTELS STATS ===")
    all_hotels = search_hotels("Tokyo", "2024-12-01", "2024-12-05")
    print(f"Total hotels found: {len(all_hotels)}")
    
    print("\n=== FLIGHTS (First 3) ===")
    flights = search_flights("SFO", "NRT", "2024-12-01")
    print(json.dumps(flights[:3], indent=2))
    
    print("\n=== ACTIVITIES (First 3) ===")
    activities = search_activities("Tokyo", limit=3)
    print(json.dumps(activities[:3], indent=2))
