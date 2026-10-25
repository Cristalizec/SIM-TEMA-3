
import streamlit as st

from views.dashboard import mostrar_dashboard


# Configuración de la ventana
st.set_page_config(
    page_title="Delivery Random Simulator",
    page_icon="📦",
    layout="wide",
    initial_sidebar_state="expanded"
)


# Estilos visuales
st.markdown("""
<style>

    .block-container {
        padding-top: 2rem;
        padding-bottom: 2rem;
    }

    div[data-testid="stMetric"] {
        background-color: rgba(130, 130, 130, 0.08);
        padding: 16px;
        border-radius: 10px;
        border: 1px solid rgba(130, 130, 130, 0.15);
    }

    div.stButton > button {
        border-radius: 8px;
        font-weight: 600;
    }

</style>
""", unsafe_allow_html=True)


# Ejecutar interfaz
def main():

    mostrar_dashboard()


if __name__ == "__main__":

    main()
