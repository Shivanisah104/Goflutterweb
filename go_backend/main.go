package main

import (
	"database/sql"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"

	_ "github.com/go-sql-driver/mysql"
	"github.com/gorilla/mux"
	"github.com/rs/cors"
	"gopkg.in/gomail.v2"
    "go get github.com/edgedb/edgedb-go"
)

type User struct {
	FirstName   string `json:"first_name"`
	LastName    string `json:"last_name"`
	DOB         string `json:"dob"`
	Email       string `json:"email"`
	PhoneNumber string `json:"phone_number"`
	CV          string `json:"cv"`
	FileName    string `json:"filename"`
}

func main() {
	fmt.Println("Starting Server")
	router := mux.NewRouter()
	router.HandleFunc("/register", registerHandler).Methods("POST")

	
	corsHandler := cors.Default().Handler(router)

	log.Fatal(http.ListenAndServe(":8080", corsHandler))
}

func sendEmail(to, subject, body string) error {
	
	m := gomail.NewMessage()
	m.SetHeader("From", "sah.shivani2401@gmail.com")
	m.SetHeader("To", to)
	m.SetHeader("Subject", subject)
	m.SetBody("text/html", body)
	fmt.Println(to)
	fmt.Println(subject)
	fmt.Println(body)

	d := gomail.NewDialer("smtp.gmail.com", 587, "sah.shivani2401@gmail.com", "horglwhspfkztyfm")
	fmt.Println("Sending Email")
	
	if err := d.DialAndSend(m); err != nil {
		fmt.Println(err)
		return err
	}
	fmt.Println("Email Sent")
	return nil
}

func registerHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("Request Came")
	decoder := json.NewDecoder(r.Body)
	var user User
	err := decoder.Decode(&user)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	decoded, err := base64.StdEncoding.DecodeString(user.CV)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	rand.Seed(time.Now().UnixNano())
	randomNum := rand.Intn(100000)

	
	uploadDir := "Resumes_"
	uploadPath := filepath.Join(uploadDir, strconv.Itoa(randomNum))

	
	err = os.MkdirAll(uploadDir, 0755)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	
	file, err := os.Create(uploadPath)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer file.Close()

	
	_, err = file.Write(decoded)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	fmt.Println("File Created")
	filePath := file.Name()
	fmt.Println("Path" + filePath)

	
	conn, err := edgedb.Connect(context.Background(), "edgedb://localhost:1024/userdetails")
    if err != nil {
        panic(err)
    }
    defer conn.Close()

	
	result, err := conn.Execute(context.Background(), `
        INSERT User {
            name := <str>'John Doe',
            age := <int64>30
            FirstName := <str>'FirstName'    
	        LastName := <str>'LastName'   
	        DOB := <str>'Date'         
	        Email := <str>'Email'      
	        PhoneNumber := <str>'PhoneNumber'
	        CVName := <str>'FileName'     
	        CVPath := <str>'filePath'   
        }
    `)
    if err != nil {
        panic(err)
    }

	

	err = sendEmail(user.Email, "Registration Confirmation", "Thank you for registering!")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	response := map[string]string{"message": "Registration successful"}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}